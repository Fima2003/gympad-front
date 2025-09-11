part of 'save_workout_bloc.dart';

abstract class SaveWorkoutEvent extends Equatable {
  const SaveWorkoutEvent();

  @override
  List<Object> get props => [];
}

class SaveWorkoutSetExercises extends SaveWorkoutEvent {
  final List<WorkoutExercise> exercises;

  const SaveWorkoutSetExercises(this.exercises);
  @override
  List<Object> get props => [exercises];
}

class SaveWorkoutEditExercise extends SaveWorkoutEvent {
  final int index;
  const SaveWorkoutEditExercise(this.index);

  @override
  List<Object> get props => [index];
}

class SaveWorkoutCloseEditor extends SaveWorkoutEvent {}

class SaveWorkoutSwitch extends SaveWorkoutEvent {
  final bool info;
  const SaveWorkoutSwitch(this.info);

  @override
  List<Object> get props => [info];
}

class SaveWorkoutUpdateName extends SaveWorkoutEvent {
  final String name;
  const SaveWorkoutUpdateName(this.name);

  @override
  List<Object> get props => [name];
}

class SaveWorkoutUpdateDescription extends SaveWorkoutEvent {
  final String description;
  const SaveWorkoutUpdateDescription(this.description);

  @override
  List<Object> get props => [description];
}

class SaveWorkoutUpdateExercise extends SaveWorkoutEvent {
  final int idx;
  final WorkoutExercise? exercise;
  const SaveWorkoutUpdateExercise(this.idx, this.exercise);

  @override
  List<Object> get props => [idx, exercise ?? 'null'];
}

class SaveWorkoutModifySet extends SaveWorkoutEvent {
  final int exerciseIdx;
  final int setIdx;
  final int? reps;
  final double? weight;
  final int? restSeconds;
  const SaveWorkoutModifySet({
    required this.exerciseIdx,
    required this.setIdx,
    this.reps,
    this.weight,
    this.restSeconds,
  });

  @override
  List<Object> get props => [
    exerciseIdx,
    setIdx,
    reps ?? 'null',
    weight ?? 'null',
    restSeconds ?? 'null',
  ];
}

class SaveWorkoutAddSet extends SaveWorkoutEvent {
  final int exerciseIdx;
  const SaveWorkoutAddSet(this.exerciseIdx);

  @override
  List<Object> get props => [exerciseIdx];
}

class SaveWorkoutRemoveSet extends SaveWorkoutEvent {
  final int exerciseIdx;
  final int setIdx;
  const SaveWorkoutRemoveSet(this.exerciseIdx, this.setIdx);

  @override
  List<Object> get props => [exerciseIdx, setIdx];
}

class SaveWorkoutUpload extends SaveWorkoutEvent {}
