import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/workout.dart';
import 'adapters/hive_workout.dart';
import 'hive_initializer.dart';

/// Handles persistence of the single in-progress workout (current workout).
/// Keeps concerns (serialization, Hive box management, error handling) isolated
/// from higher-level workflow logic in WorkoutService.
class CurrentWorkoutLocalStorageService {
  static const String _boxName = 'current_workout_box';
  static const String _key = 'current';

  Future<Box<HiveWorkout>> _box() async {
    await HiveInitializer.init();
    return Hive.isBoxOpen(_boxName)
        ? Hive.box<HiveWorkout>(_boxName)
        : Hive.openBox<HiveWorkout>(_boxName);
  }

  Future<void> save(Workout workout) async {
    try {
      final box = await _box();
      final hiveModel = HiveWorkout.fromDomain(workout);
      await box.put(_key, hiveModel);
    } catch (e, st) {
      log(
        'CurrentWorkoutLocalStorageService.save failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<Workout?> load() async {
    try {
      final box = await _box();
      final hiveModel = box.get(_key);
      return hiveModel?.toDomain();
    } catch (e, st) {
      log(
        'CurrentWorkoutLocalStorageService.load failed',
        error: e,
        stackTrace: st,
      );
      return null; // Non-fatal; caller can treat as no current workout
    }
  }

  Future<void> clear() async {
    try {
      final box = await _box();
      await box.delete(_key);
    } catch (e, st) {
      log(
        'CurrentWorkoutLocalStorageService.clear failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
