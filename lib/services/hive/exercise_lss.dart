import '../../models/withAdapters/exercise.dart';
import 'lss.dart';

/// Local storage service for Exercise domain models.
class ExerciseLss extends LSS<Exercise, Exercise> {
  ExerciseLss() : super('exercises');

  @override
  Exercise fromDomain(Exercise domain) => domain;

  @override
  Exercise toDomain(Exercise hive) => hive;

  @override
  String getKey(Exercise domain) => domain.exerciseId;
}
