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
  final bool uploading;

  const SaveWorkoutInfo(this.name, this.description, this.uploading);

  @override
  List<Object?> get props => [name, description, uploading];
}

class SaveWorkoutExercises extends SaveWorkoutState {
  final List<WorkoutExercise> exercises;
  final int? editIndex;

  const SaveWorkoutExercises(this.exercises, {this.editIndex});
  @override
  List<Object?> get props => [exercises, editIndex];
}

class SaveWorkoutError extends SaveWorkoutState {
  final String? nameError;
  final String? descriptionError;
  final String name;
  final String description;
  final String? error;
  const SaveWorkoutError(
    this.name,
    this.description, {
    this.nameError,
    this.descriptionError,
    this.error,
  });

  @override
  List<Object?> get props => [nameError, descriptionError, error];
}

class SaveWorkoutSuccess extends SaveWorkoutState {
  final bool success;

  const SaveWorkoutSuccess(this.success);
  @override
  List<Object?> get props => [success];
}
