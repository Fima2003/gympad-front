part of 'workout_bloc.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class WorkoutStarted extends WorkoutEvent {
  final WorkoutType type;
  final CustomWorkout? workoutToFollow;

  const WorkoutStarted(this.type, {this.workoutToFollow});

  @override
  List<Object?> get props => [type, workoutToFollow];
}

class WorkoutFinished extends WorkoutEvent {}

class ExerciseAdded extends WorkoutEvent {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final String? equipmentId;

  const ExerciseAdded({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    this.equipmentId,
  });

  @override
  List<Object?> get props => [exerciseId, name, muscleGroup, equipmentId];
}

class ExerciseFinished extends WorkoutEvent {}

class SetAdded extends WorkoutEvent {
  final int reps;
  final double weight;
  final Duration duration;

  const SetAdded({
    required this.reps,
    required this.weight,
    required this.duration,
  });

  @override
  List<Object> get props => [reps, weight, duration];
}

class WorkoutLoaded extends WorkoutEvent {}

class WorkoutHistoryRequested extends WorkoutEvent {}
