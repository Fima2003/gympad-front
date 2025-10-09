import '../../models/custom_workout.dart';
import 'adapters/hive_custom_workout.dart';
import 'lss.dart';

class WorkoutToFollowLss extends LSS<CustomWorkout, HiveCustomWorkout> {
  WorkoutToFollowLss()
    : super('workout_to_follow_box', defaultKey: 'workout_to_follow');

  @override
  HiveCustomWorkout fromDomain(CustomWorkout domain) =>
      HiveCustomWorkout.fromDomain(domain);

  @override
  CustomWorkout toDomain(HiveCustomWorkout hive) => hive.toDomain();

  @override
  String getKey(CustomWorkout domain) => 'workout_to_follow';
}
