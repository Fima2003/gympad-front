import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';
import '../../services/api/models/personal_workout.model.dart';
import '../../services/personal_workout_service.dart';

part 'save_workout_events.dart';
part 'save_workout_state.dart';

class SaveWorkoutBloc extends Bloc<SaveWorkoutEvent, SaveWorkoutState> {
  final PersonalWorkoutService _personalWorkoutService =
      PersonalWorkoutService();
  String name = '';
  String description = '';
  List<WorkoutExercise> exercises = [];
  SaveWorkoutBloc() : super(SaveWorkoutInitial()) {
    on<SaveWorkoutUpdateName>(_updateName);
    on<SaveWorkoutUpdateDescription>(_updateDescription);
    on<SaveWorkoutSetExercises>(_setExercises);
    on<SaveWorkoutUpdateExercise>(_updateExercise);
    on<SaveWorkoutModifySet>(_modifySet);
    on<SaveWorkoutAddSet>(_addSet);
    on<SaveWorkoutRemoveSet>(_removeSet);
    on<SaveWorkoutSwitch>(_switch);
    on<SaveWorkoutUpload>(_upload);
    on<SaveWorkoutEditExercise>(_editExercise);
    on<SaveWorkoutCloseEditor>(_closeEditor);
  }

  void _updateName(
    SaveWorkoutUpdateName event,
    Emitter<SaveWorkoutState> emit,
  ) {
    name = event.name;
    emit(SaveWorkoutInfo(name, description, false));
  }

  bool _validateName(String name) {
    final regex = RegExp(r'^[a-zA-Z0-9 ]+$');
    return name.length > 6 && regex.hasMatch(name);
  }

  void _updateDescription(
    SaveWorkoutUpdateDescription event,
    Emitter<SaveWorkoutState> emit,
  ) {
    description = event.description;
    emit(SaveWorkoutInfo(name, description, false));
  }

  bool _validateDescription(String description) {
    final regex = RegExp(r'^[a-zA-Z0-9 ]+$');
    return regex.hasMatch(description);
  }

  void _editExercise(
    SaveWorkoutEditExercise event,
    Emitter<SaveWorkoutState> emit,
  ) {
    final index = event.index;
    if (index < 0 || index >= exercises.length) return;
    emit(SaveWorkoutExercises(List.unmodifiable(exercises), editIndex: index));
  }

  void _closeEditor(
    SaveWorkoutCloseEditor event,
    Emitter<SaveWorkoutState> emit,
  ) {
    // Re-emit exercises without edit index to signal sheet closed.
    emit(SaveWorkoutExercises(List.unmodifiable(exercises)));
  }

  void _setExercises(
    SaveWorkoutSetExercises event,
    Emitter<SaveWorkoutState> emit,
  ) {
    exercises = List<WorkoutExercise>.from(event.exercises);
    emit(SaveWorkoutExercises(List.unmodifiable(exercises)));
  }

  void _updateExercise(
    SaveWorkoutUpdateExercise event,
    Emitter<SaveWorkoutState> emit,
  ) {
    final idxToReplace = event.idx;
    final exerciseToReplace = event.exercise;
    if (exerciseToReplace != null) {
      final newList = List<WorkoutExercise>.from(exercises);
      newList[idxToReplace] = exerciseToReplace;
      exercises = newList;
    } else {
      final newList = List<WorkoutExercise>.from(exercises)
        ..removeAt(idxToReplace);
      exercises = newList;
    }
    emit(SaveWorkoutExercises(List.unmodifiable(exercises)));
  }

  void _modifySet(SaveWorkoutModifySet event, Emitter<SaveWorkoutState> emit) {
    if (event.exerciseIdx < 0 || event.exerciseIdx >= exercises.length) return;
    final exercise = exercises[event.exerciseIdx];
    if (event.setIdx < 0 || event.setIdx >= exercise.sets.length) return;
    final sets = List<WorkoutSet>.from(exercise.sets);
    final current = sets[event.setIdx];
    sets[event.setIdx] = current.copyWith(
      reps: event.reps ?? current.reps,
      weight: event.weight ?? current.weight,
      time:
          event.restSeconds != null
              ? Duration(seconds: event.restSeconds!)
              : current.time,
    );
    final newExercises = List<WorkoutExercise>.from(exercises);
    newExercises[event.exerciseIdx] = exercise.copyWith(sets: sets);
    exercises = newExercises;
    emit(SaveWorkoutExercises(List.unmodifiable(exercises)));
  }

  void _addSet(SaveWorkoutAddSet event, Emitter<SaveWorkoutState> emit) {
    if (event.exerciseIdx < 0 || event.exerciseIdx >= exercises.length) return;
    final exercise = exercises[event.exerciseIdx];
    final sets = List<WorkoutSet>.from(exercise.sets);
    sets.add(
      WorkoutSet(
        setNumber: sets.length + 1,
        reps: sets.last.reps,
        weight: sets.last.weight,
        time: sets.last.time,
      ),
    );
    final newExercises = List<WorkoutExercise>.from(exercises);
    newExercises[event.exerciseIdx] = exercise.copyWith(sets: sets);
    exercises = newExercises;
    emit(SaveWorkoutExercises(List.unmodifiable(exercises)));
  }

  void _removeSet(SaveWorkoutRemoveSet event, Emitter<SaveWorkoutState> emit) {
    if (event.exerciseIdx < 0 || event.exerciseIdx >= exercises.length) return;
    final exercise = exercises[event.exerciseIdx];
    if (event.setIdx < 0 || event.setIdx >= exercise.sets.length) return;
    final sets = List<WorkoutSet>.from(exercise.sets)..removeAt(event.setIdx);
    // Re-number sets
    final renumbered = <WorkoutSet>[];
    for (var i = 0; i < sets.length; i++) {
      final s = sets[i];
      renumbered.add(s.copyWith(setNumber: i + 1));
    }
    final newExercises = List<WorkoutExercise>.from(exercises);
    newExercises[event.exerciseIdx] = exercise.copyWith(sets: renumbered);
    exercises = newExercises;
    emit(SaveWorkoutExercises(List.unmodifiable(exercises)));
  }

  void _switch(SaveWorkoutSwitch event, Emitter<SaveWorkoutState> emit) {
    if (event.info) {
      emit(SaveWorkoutInfo(name, description, false));
    } else {
      emit(SaveWorkoutExercises(List.unmodifiable(exercises)));
    }
  }

  Future<void> _upload(
    SaveWorkoutUpload event,
    Emitter<SaveWorkoutState> emit,
  ) async {
    emit(SaveWorkoutInfo(name, description, true));
    // Validate on final upload
    if (!_validateName(name)) {
      emit(
        SaveWorkoutError(
          name,
          description,
          nameError: "At least 6 characters, english and numbers only",
        ),
      );
      return;
    }
    if (description != '' && !_validateDescription(description)) {
      emit(
        SaveWorkoutError(
          name,
          description,
          descriptionError: "English and numbers only",
        ),
      );
      return;
    }
    final exercisesDto =
        exercises.map((ex) {
          final reps =
              ex.sets.isNotEmpty
                  ? ex.sets.map((s) => s.reps).reduce((a, b) => a + b) ~/
                      ex.sets.length
                  : 0;
          final avgWeight =
              ex.sets.isNotEmpty
                  ? ex.sets.map((s) => s.weight).reduce((a, b) => a + b) /
                      ex.sets.length
                  : 0.0;
          final restTime = ex.sets.length > 1 ? _estimateRestTime(ex.sets) : 0;
          return PersonalWorkoutExerciseDto(
            exerciseId: ex.exerciseId,
            name: ex.name,
            sets: ex.sets.length,
            reps: reps,
            weight: avgWeight,
            restTime: restTime,
          );
        }).toList();

    final req = CreatePersonalWorkoutRequest(
      name: name,
      description: description,
      exercises: exercisesDto,
    );
    final resp = await _personalWorkoutService.savePersonalWorkout(req);
    emit(SaveWorkoutSuccess(resp));
  }

  int _estimateRestTime(List sets) {
    return 60;
  }
}
