import '../../models/workout.dart';
import 'adapters/hive_workout.dart';
import 'lss.dart';

class WorkoutHistoryLocalStorageService extends LSS<Workout, HiveWorkout> {
  WorkoutHistoryLocalStorageService() : super('workout_history_box');

  @override
  HiveWorkout fromDomain(Workout domain) => HiveWorkout.fromDomain(domain);

  @override
  Workout toDomain(HiveWorkout hive) => hive.toDomain();

  @override
  String getKey(Workout domain) => domain.id;

  Future<void> markUploaded(String workoutId) =>
      update(key: workoutId, copyWithFn: (w) => w.copyWith(isUploaded: true));
}
