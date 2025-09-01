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

class WorkoutCancelled extends WorkoutEvent {}

class WorkoutFinished extends WorkoutEvent {
  final int? reps;
  final double? weight;
  final Duration? duration;
  const WorkoutFinished({this.reps, this.weight, this.duration});

  @override
  List<Object?> get props => [reps, weight, duration];
}

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

class ExerciseFinished extends WorkoutEvent {
  final int reps;
  final double weight;
  final Duration duration;

  const ExerciseFinished({
    required this.reps,
    required this.weight,
    required this.duration,
  });
}

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

class UpcomingExercisesReordered extends WorkoutEvent {
  final int startIndex; // index in workoutToFollow.exercises where reordering begins
  final List<String> newOrderIds; // ids of exercises in their new order for the reorderable suffix

  const UpcomingExercisesReordered(this.startIndex, this.newOrderIds);

  @override
  List<Object?> get props => [startIndex, newOrderIds];
}
