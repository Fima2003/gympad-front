import '../../models/personal_workout.dart';
import 'adapters/hive_personal_workout.dart';
import 'lss.dart';

class PersonalWorkoutLocalService
    extends LSS<PersonalWorkout, HivePersonalWorkout> {
  PersonalWorkoutLocalService() : super("personal_workouts_box");

  @override
  getKey(PersonalWorkout domain) => domain.workoutId;

  @override
  PersonalWorkout toDomain(HivePersonalWorkout hive) => hive.toDomain();

  @override
  fromDomain(PersonalWorkout domain) => HivePersonalWorkout.fromDomain(domain);
}
