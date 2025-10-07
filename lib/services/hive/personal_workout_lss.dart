import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/models/personal_workout.model.dart';
import '../../models/personal_workout.dart';
import 'adapters/hive_personal_workout.dart';
import 'hive_initializer.dart';

/// Local persistence for Personal Workouts using Hive (strongly typed).
/// Responsibilities:
///  - Initialize & access the Hive box for personal workouts
///  - Map API/domain models to Hive objects and back
///  - Provide CRUD-style operations (currently bulk save & load + clear)
class PersonalWorkoutLocalService {
  static final PersonalWorkoutLocalService _instance =
      PersonalWorkoutLocalService._internal();
  factory PersonalWorkoutLocalService() => _instance;
  PersonalWorkoutLocalService._internal();

  static const String _boxName = 'personal_workouts_box';

  Future<Box<HivePersonalWorkout>> _openBox() async {
    await HiveInitializer.init();
    return Hive.isBoxOpen(_boxName)
        ? Hive.box<HivePersonalWorkout>(_boxName)
        : Hive.openBox<HivePersonalWorkout>(_boxName);
  }

  /// Persist (replace) all personal workouts from API responses.
  Future<void> saveAll(List<PersonalWorkoutResponse> workouts) async {
    final box = await _openBox();
    try {
      await box.clear();
      final hiveList =
          workouts
              .map(
                (w) => HivePersonalWorkout.fromDomain(
                  PersonalWorkout.fromResponse(w),
                ),
              )
              .toList();
      // Use putAll with incremental keys for deterministic ordering.
      final entries = <int, HivePersonalWorkout>{};
      for (var i = 0; i < hiveList.length; i++) {
        entries[i] = hiveList[i];
      }
      await box.putAll(entries);
    } catch (e, st) {
      log('Failed to save personal workouts to Hive', error: e, stackTrace: st);
      rethrow; // Let caller decide error handling policy.
    }
  }

  /// Load all workouts (domain model). Returns empty list on any parsing error.
  Future<List<PersonalWorkout>> loadAll() async {
    final box = await _openBox();
    try {
      return box.values.map((h) => h.toDomain()).toList(growable: false);
    } catch (e, st) {
      log(
        'Failed to load personal workouts from Hive',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<void> updateExercises(
    String workoutId,
    List<PersonalWorkoutExercise> exercises,
  ) async {
    final box = await _openBox();
    try {
      final index = box.values.toList().indexWhere(
        (w) => w.workoutId == workoutId,
      );
      if (index == -1) {
        log('Workout with id $workoutId not found in Hive box');
        return;
      }
      final hivePWorkout = box.getAt(index);
      if (hivePWorkout == null) {
        log('Workout at index $index is null in Hive box');
        return;
      }
      final existingExercises = hivePWorkout.exercises;
      final newExercises =
          existingExercises.map((e) {
            final replacement = exercises.firstWhere(
              (ex) => ex.exerciseId == e.exerciseId,
              orElse: () => e.toDomain(),
            );
            return replacement;
          }).toList();
      final updatedHiveWorkout = hivePWorkout.copyWith(
        exercises:
            newExercises.map(HivePersonalWorkoutExercise.fromDomain).toList(),
      );
      await box.putAt(index, updatedHiveWorkout);
    } catch (e, st) {
      log(
        'Failed to update exercises of workout $workoutId in Hive',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Clear all persisted workouts.
  Future<void> clear() async {
    final box = await _openBox();
    try {
      await box.clear();
    } catch (e, st) {
      log(
        'Failed to clear personal workouts Hive box',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
