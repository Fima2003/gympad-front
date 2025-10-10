import '../../models/workout.dart';
import 'adapters/hive_workout.dart';
import 'lss.dart';

/// Hive-backed persistence for workout history (completed or in-progress past sessions).
/// Each workout stored with its id as key for efficient updates.
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
