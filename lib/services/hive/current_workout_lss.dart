import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/custom_workout.dart';
import '../../models/workout.dart';
import 'adapters/hive_workout.dart';
import 'hive_initializer.dart';
import 'adapters/hive_custom_workout.dart';

/// Handles persistence of the single in-progress workout (current workout).
/// Keeps concerns (serialization, Hive box management, error handling) isolated
/// from higher-level workflow logic in WorkoutService.
class CurrentWorkoutLocalStorageService {
  static const String _boxName = 'current_workout_box';
  static const String _key = 'current';
  static const String _toFollowBoxName = 'workout_to_follow_box';
  static const String _keyToFollow = 'workout_to_follow';

  Future<Box<HiveWorkout>> _box() async {
    await HiveInitializer.init();
    return Hive.isBoxOpen(_boxName)
        ? Hive.box<HiveWorkout>(_boxName)
        : Hive.openBox<HiveWorkout>(_boxName);
  }

  Future<Box<HiveCustomWorkout>> _toFollowBox() async {
    await HiveInitializer.init();
    return Hive.isBoxOpen(_toFollowBoxName)
        ? Hive.box<HiveCustomWorkout>(_toFollowBoxName)
        : Hive.openBox<HiveCustomWorkout>(_toFollowBoxName);
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

  Future<void> saveWorkoutToFollow(CustomWorkout customWorkout) async {
    try {
      final box = await _toFollowBox();
      final hiveModel = HiveCustomWorkout.fromDomain(customWorkout);
      await box.put(_keyToFollow, hiveModel);
    } catch (e, st) {
      log(
        'CurrentWorkoutLocalStorageService.saveWorkoutToFollow failed',
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

  Future<CustomWorkout?> loadWorkoutToFollow() async {
    try {
      final box = await _toFollowBox();
      final hiveModel = box.get(_keyToFollow);
      return hiveModel?.toDomain();
    } catch (e, st) {
      log(
        'CurrentWorkoutLocalStorageService.loadWorkoutToFollow failed',
        error: e,
        stackTrace: st,
      );
      return null; // treat as none
    }
  }

  Future<void> clear() async {
    try {
      final box = await _box();
      await box.delete(_key);
      if (Hive.isBoxOpen(_toFollowBoxName)) {
        final toFollow = Hive.box<HiveCustomWorkout>(_toFollowBoxName);
        await toFollow.delete(_keyToFollow);
      } else if (await Hive.boxExists(_toFollowBoxName)) {
        final toFollow = await Hive.openBox<HiveCustomWorkout>(
          _toFollowBoxName,
        );
        await toFollow.delete(_keyToFollow);
      }
    } catch (e, st) {
      log(
        'CurrentWorkoutLocalStorageService.clear failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> deleteWorkoutToFollowOnly() async {
    try {
      final box = await _toFollowBox();
      await box.delete(_keyToFollow);
    } catch (e, st) {
      log(
        'CurrentWorkoutLocalStorageService.deleteWorkoutToFollowOnly failed',
        error: e,
        stackTrace: st,
      );
    }
  }
}
