part of 'personal_workout_bloc.dart';

abstract class PersonalWorkoutState extends Equatable {
  const PersonalWorkoutState();
  @override
  List<Object?> get props => [];
}

class PersonalWorkoutInitial extends PersonalWorkoutState {
  const PersonalWorkoutInitial();
}

class PersonalWorkoutsLoaded extends PersonalWorkoutState {
  final List<PersonalWorkout> workouts;

  const PersonalWorkoutsLoaded(this.workouts);

  @override
  List<Object> get props => [workouts];
}
