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
  final CustomWorkout? workoutToFollow;
  final int currentExerciseIdx;
  final int currentSetIdx;
  final double? progress; // between 0 to 100

  const WorkoutInProgress(
    this.workout, {
    this.workoutToFollow,
    required this.currentExerciseIdx,
    required this.currentSetIdx,
    this.progress,
  });

  @override
  List<Object?> get props => [
    workout,
    workoutToFollow,
    currentExerciseIdx,
    currentSetIdx,
    progress,
  ];
}

class AddingExercise extends WorkoutState {}

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
