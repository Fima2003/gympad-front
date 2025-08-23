import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/workout.dart';
import 'adapters/hive_workout.dart';
import 'hive_initializer.dart';

/// Hive-backed persistence for workout history (completed or in-progress past sessions).
/// Each workout stored with its id as key for efficient updates.
class WorkoutHistoryLocalStorageService {
  static const String _boxName = 'workout_history_box';

  Future<Box<HiveWorkout>> _box() async {
    await HiveInitializer.init();
    return Hive.isBoxOpen(_boxName)
        ? Hive.box<HiveWorkout>(_boxName)
        : Hive.openBox<HiveWorkout>(_boxName);
  }

  Future<List<Workout>> getAll() async {
    try {
      final box = await _box();
      return box.values.map((e) => e.toDomain()).toList(growable: false);
    } catch (e, st) {
      log(
        'WorkoutHistoryLocalStorageService.getAll failed',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<void> add(Workout workout) async {
    try {
      final box = await _box();
      await box.put(workout.id, HiveWorkout.fromDomain(workout));
    } catch (e, st) {
      log(
        'WorkoutHistoryLocalStorageService.add failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> addAll(List<Workout> workouts) async {
    try {
      final box = await _box();
      final map = <String, HiveWorkout>{
        for (final w in workouts) w.id: HiveWorkout.fromDomain(w),
      };
      await box.putAll(map);
    } catch (e, st) {
      log(
        'WorkoutHistoryLocalStorageService.addAll failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> markUploaded(String workoutId) async {
    try {
      final box = await _box();
      final existing = box.get(workoutId);
      if (existing != null && !existing.isUploaded) {
        final updated = HiveWorkout(
          id: existing.id,
          name: existing.name,
          exercises: existing.exercises,
          startTime: existing.startTime,
          endTime: existing.endTime,
          isUploaded: true,
          isOngoing: existing.isOngoing,
        );
        await box.put(workoutId, updated);
      }
    } catch (e, st) {
      log(
        'WorkoutHistoryLocalStorageService.markUploaded failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> clear() async {
    try {
      final box = await _box();
      await box.clear();
    } catch (e, st) {
      log(
        'WorkoutHistoryLocalStorageService.clear failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
