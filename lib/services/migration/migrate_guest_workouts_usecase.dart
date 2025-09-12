import 'dart:async';

import 'package:gympad/models/capabilities.dart';
import 'package:gympad/services/hive/workout_history_lss.dart';
import 'package:gympad/services/logger_service.dart';
import 'package:gympad/services/workout_service.dart';
import 'package:gympad/models/workout.dart';

class MigrationProgress {
  final int total;
  final int processed;
  final int succeeded;
  final int failed;
  const MigrationProgress({
    required this.total,
    required this.processed,
    required this.succeeded,
    required this.failed,
  });
}

class MigrationResult {
  final int succeeded;
  final int failed;
  final List<String> failedIds;
  final Duration elapsed;
  final bool skipped;
  const MigrationResult({
    required this.succeeded,
    required this.failed,
    required this.failedIds,
    required this.elapsed,
    this.skipped = false,
  });

  factory MigrationResult.empty({bool skipped = false}) => MigrationResult(
    succeeded: 0,
    failed: 0,
    failedIds: const [],
    elapsed: Duration.zero,
    skipped: skipped,
  );
}

/// Use case to migrate guest-created workouts (createdWhileGuest && !isUploaded)
/// once the user authenticates. Idempotent: re-running has no side effects
/// because uploaded workouts are filtered out by flags.
class MigrateGuestWorkoutsUseCase {
  final WorkoutHistoryLocalStorageService _history;
  final WorkoutService _workoutService;
  final CapabilitiesProvider _caps;
  final AppLogger _logger = AppLogger();

  MigrateGuestWorkoutsUseCase({
    WorkoutHistoryLocalStorageService? history,
    WorkoutService? workoutService,
    CapabilitiesProvider? capabilitiesProvider,
  }) : _history = history ?? WorkoutHistoryLocalStorageService(),
       _workoutService = workoutService ?? WorkoutService(),
       _caps = capabilitiesProvider ?? (() => Capabilities.guest);

  Future<MigrationResult> run({
    void Function(MigrationProgress p)? onProgress,
  }) async {
    final start = DateTime.now();
    if (!_caps().canUpload) {
      return MigrationResult.empty(skipped: true);
    }
    List<Workout> all;
    try {
      all = await _history.getAll();
    } catch (e, st) {
      _logger.warning('Migration: failed to load history', e, st);
      return MigrationResult.empty(skipped: true);
    }
    final targets = all
        .where((w) => !w.isUploaded && w.createdWhileGuest)
        .toList(growable: false);
    if (targets.isEmpty) {
      return MigrationResult.empty();
    }

    int processed = 0, succeeded = 0;
    final failedIds = <String>[];
    const batchSize = 5;
    for (var i = 0; i < targets.length; i += batchSize) {
      final batch = targets.skip(i).take(batchSize);
      for (final w in batch) {
        final ok = await _attemptUpload(w);
        processed++;
        if (ok) {
          succeeded++;
        } else {
          failedIds.add(w.id);
        }
        onProgress?.call(
          MigrationProgress(
            total: targets.length,
            processed: processed,
            succeeded: succeeded,
            failed: failedIds.length,
          ),
        );
      }
      if (i + batchSize < targets.length) {
        await Future.delayed(Duration(milliseconds: (i ~/ batchSize) * 150));
      }
    }

    final result = MigrationResult(
      succeeded: succeeded,
      failed: failedIds.length,
      failedIds: failedIds,
      elapsed: DateTime.now().difference(start),
    );
    _logger.info(
      'Guest migration finished: total=${targets.length} succeeded=$succeeded failed=${failedIds.length} elapsed=${result.elapsed.inMilliseconds}ms',
    );
    return result;
  }

  Future<bool> _attemptUpload(Workout w) async {
    try {
      // Reuse existing batch mechanism; _uploadWorkout is private.
      // Approach: call uploadPendingWorkouts after ensuring this workout is still pending.
      if (w.isUploaded) return true; // Already handled by another process.
      await _workoutService.uploadPendingWorkouts();
      // Check if it flipped to uploaded
      final refreshed = await _history.getAll();
      final updated = refreshed.firstWhere(
        (x) => x.id == w.id,
        orElse: () => w,
      );
      return updated.isUploaded;
    } catch (e, st) {
      _logger.warning('Migration: upload attempt failed id=${w.id}', e, st);
      return false;
    }
  }
}
