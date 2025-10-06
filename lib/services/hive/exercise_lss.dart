import 'package:hive/hive.dart';

import '../../models/exercise.dart';
import '../logger_service.dart';
import 'adapters/hive_exercise.dart';
import 'hive_initializer.dart';

class ExerciseLss {
  static const String _boxName = 'exercises';
  final _logger = AppLogger().createLogger('ExercisesLss');

  Future<Box<HiveExercise>> _box() async {
    await HiveInitializer.init();
    return Hive.isBoxOpen(_boxName)
        ? Hive.box<HiveExercise>(_boxName)
        : Hive.openBox<HiveExercise>(_boxName);
  }

  Future<void> save(Exercise exercise) async {
    final box = await _box();
    final hiveExercise = HiveExercise.fromDomain(exercise);
    await box.put(hiveExercise.exerciseId, hiveExercise);
    _logger.fine('Saved exercise: ${exercise.id}');
  }

  Future<Exercise?> getById(String id) async {
    final box = await _box();
    final hiveExercise = box.get(id);
    if (hiveExercise != null) {
      _logger.fine('Retrieved exercise: $id');
      return hiveExercise.toDomain();
    } else {
      _logger.warning('Exercise not found: $id');
      return null;
    }
  }

  Future<List<Exercise>> getAll() async {
    final box = await _box();
    final exercises =
        box.values.map((hiveExercise) => hiveExercise.toDomain()).toList();
    _logger.fine('Retrieved all exercises, count: ${exercises.length}');
    return exercises;
  }

  Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
    _logger.fine('Deleted exercise: $id');
  }

  Future<void> clear() async {
    final box = await _box();
    await box.clear();
    _logger.fine('Cleared all exercises');
  }
}
