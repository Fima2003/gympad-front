part of 'save_workout_bloc.dart';

abstract class SaveWorkoutState extends Equatable {
  const SaveWorkoutState();

  @override
  List<Object?> get props => [];
}

class SaveWorkoutInitial extends SaveWorkoutState {}

class SaveWorkoutInfo extends SaveWorkoutState {
  final String name;
  final String description;

  const SaveWorkoutInfo(this.name, this.description);

  @override
  List<Object?> get props => [name, description];
}

class SaveWorkoutExercises extends SaveWorkoutState {
  final List<WorkoutExercise> exercises;

  const SaveWorkoutExercises(this.exercises);
  @override
  List<Object?> get props => [exercises];
}

class SaveWorkoutError extends SaveWorkoutState {
  final String? nameError;
  final String? descriptionError;
  final String? error;
  const SaveWorkoutError({this.nameError, this.descriptionError, this.error});

  @override
  List<Object?> get props => [nameError, descriptionError, error];
}

class SaveWorkoutSuccess extends SaveWorkoutState {
  final bool success;

  const SaveWorkoutSuccess(this.success);
  @override
  List<Object?> get props => [success];
}
