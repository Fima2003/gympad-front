import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

import '../../models/custom_workout.dart';
import '../logger_service.dart';
import 'adapters/hive_custom_workout.dart';
import 'hive_initializer.dart';

class CustomWorkoutLss {
  static const String _boxName = 'custom_workouts';
  final _logger = AppLogger().createLogger('CustomWorkoutLss');

  Future<Box<HiveCustomWorkout>> _box() async {
    await HiveInitializer.init();
    return Hive.isBoxOpen(_boxName)
        ? Hive.box<HiveCustomWorkout>(_boxName)
        : Hive.openBox<HiveCustomWorkout>(_boxName);
  }

  Future<void> save(CustomWorkout workout) async {
    try {
      final box = await _box();
      final hiveModel = HiveCustomWorkout.fromDomain(workout);
      await box.put(workout.id, hiveModel);
    } catch (e) {
      _logger.log(
        Level.SEVERE,
        'CurrentWorkoutLocalStorageService.save failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> saveMany(List<CustomWorkout> workouts) async {
    try {
      for (var w in workouts) {
        save(w);
      }
    } catch (e) {
      _logger.log(
        Level.SEVERE,
        'CurrentWorkoutLocalStorageService.saveMany failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<CustomWorkout?> get(String workoutId) async {
    try {
      final box = await _box();
      final hiveModel = box.get(workoutId);
      if (hiveModel == null) return null;
      return hiveModel.toDomain();
    } catch (e) {
      _logger.log(
        Level.SEVERE,
        'CurrentWorkoutLocalStorageService.get failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<List<CustomWorkout>> getAll() async {
    try {
      final box = await _box();
      return box.values.map((e) => e.toDomain()).toList();
    } catch (e) {
      _logger.log(
        Level.SEVERE,
        'CurrentWorkoutLocalStorageService.getAll failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> delete(String workoutId) async {
    try {
      final box = await _box();
      await box.delete(workoutId);
    } catch (e) {
      _logger.log(
        Level.SEVERE,
        'CurrentWorkoutLocalStorageService.delete failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> clear() async {
    try {
      final box = await _box();
      await box.clear();
    } catch (e) {
      _logger.log(
        Level.SEVERE,
        'CurrentWorkoutLocalStorageService.deleteAll failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> deleteMany(List<String> workoutIds) async {
    try {
      final box = await _box();
      await box.deleteAll(workoutIds);
    } catch (e) {
      _logger.log(
        Level.SEVERE,
        'CurrentWorkoutLocalStorageService.deleteMany failed: ${e.toString()}',
      );
      rethrow;
    }
  }
}
