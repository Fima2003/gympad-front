part of 'workout_bloc.dart';

abstract class WorkoutState extends Equatable {
  const WorkoutState();
  
  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class WorkoutInProgress extends WorkoutState {
  final Workout workout;
  
  const WorkoutInProgress(this.workout);
  
  @override
  List<Object> get props => [workout];
}

class WorkoutCompleted extends WorkoutState {
  final Workout workout;
  
  const WorkoutCompleted(this.workout);
  
  @override
  List<Object> get props => [workout];
}

class WorkoutError extends WorkoutState {
  final String message;
  
  const WorkoutError(this.message);
  
  @override
  List<Object> get props => [message];
}

class WorkoutHistoryLoaded extends WorkoutState {
  final List<Workout> workouts;
  
  const WorkoutHistoryLoaded(this.workouts);
  
  @override
  List<Object> get props => [workouts];
}

class PersonalWorkoutsLoaded extends WorkoutState {
  final List<PersonalWorkout> workouts;

  const PersonalWorkoutsLoaded(this.workouts);

  @override
  List<Object> get props => [workouts];
}
