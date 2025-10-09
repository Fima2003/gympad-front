import '../../models/workout.dart';
import 'adapters/hive_workout.dart';
import 'lss.dart';

class CurrentWorkoutLocalStorageService extends LSS<Workout, HiveWorkout> {
  static const String _key = 'current';

  CurrentWorkoutLocalStorageService()
    : super('current_workout_box', defaultKey: _key);

  @override
  Workout toDomain(HiveWorkout hive) {
    return hive.toDomain();
  }

  @override
  HiveWorkout fromDomain(Workout domain) {
    return HiveWorkout.fromDomain(domain);
  }

  @override
  String getKey(Workout domain) => _key; // Always the same key for current workout
}
