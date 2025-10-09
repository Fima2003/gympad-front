import '../../models/exercise.dart';
import 'adapters/hive_exercise.dart';
import 'lss.dart';

/// Local storage service for Exercise domain models.
class ExerciseLss extends LSS<Exercise, HiveExercise> {
  ExerciseLss() : super('exercises');

  @override
  HiveExercise fromDomain(Exercise domain) => HiveExercise.fromDomain(domain);

  @override
  Exercise toDomain(HiveExercise hive) => hive.toDomain();

  @override
  String getKey(Exercise domain) => domain.id;

  // Alias methods for backward compatibility / cleaner API
  Future<Exercise?> getById(String id) => get({id});
}
