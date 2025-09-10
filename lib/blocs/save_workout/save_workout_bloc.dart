import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';
import '../../services/api/models/workout_models.dart';
import '../../services/workout_service.dart';

part 'save_workout_events.dart';
part 'save_workout_state.dart';

class SaveWorkoutBloc extends Bloc<SaveWorkoutEvent, SaveWorkoutState> {
  final WorkoutService _workoutService = WorkoutService();
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
  }

  void _updateName(
    SaveWorkoutUpdateName event,
    Emitter<SaveWorkoutState> emit,
  ) {
    name = event.name;
    emit(SaveWorkoutInfo(name, description));
  }

  bool _validateName(String name) {
    return name.length > 6;
  }

  void _updateDescription(
    SaveWorkoutUpdateDescription event,
    Emitter<SaveWorkoutState> emit,
  ) {
    description = event.description;
    emit(SaveWorkoutInfo(name, description));
  }

  bool _validateDescription(String description) {
    return true;
  }

  void _setExercises(
    SaveWorkoutSetExercises event,
    Emitter<SaveWorkoutState> emit,
  ) {
    exercises = event.exercises;
    emit(SaveWorkoutExercises(exercises));
  }

  void _updateExercise(
    SaveWorkoutUpdateExercise event,
    Emitter<SaveWorkoutState> emit,
  ) {
    final idxToReplace = event.idx;
    final exerciseToReplace = event.exercise;
    if (exerciseToReplace != null) {
      exercises[idxToReplace] = exerciseToReplace;
    } else {
      exercises.removeAt(idxToReplace);
    }
    emit(SaveWorkoutExercises(exercises));
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
    exercises[event.exerciseIdx] = exercise.copyWith(sets: sets);
    emit(SaveWorkoutExercises(exercises));
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
    exercises[event.exerciseIdx] = exercise.copyWith(sets: sets);
    emit(SaveWorkoutExercises(exercises));
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
    exercises[event.exerciseIdx] = exercise.copyWith(sets: renumbered);
    emit(SaveWorkoutExercises(exercises));
  }

  void _switch(SaveWorkoutSwitch event, Emitter<SaveWorkoutState> emit) {
    if (event.info) {
      emit(SaveWorkoutInfo(name, description));
    } else {
      emit(SaveWorkoutExercises(exercises));
    }
  }

  Future<void> _upload(
    SaveWorkoutUpload event,
    Emitter<SaveWorkoutState> emit,
  ) async {
    // Validate on final upload
    if (!_validateName(name)) {
      emit(const SaveWorkoutError(nameError: "Invalid name"));
      return;
    }
    if (!_validateDescription(description)) {
      emit(const SaveWorkoutError(descriptionError: "Invalid description"));
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
    final resp = await _workoutService.savePersonalWorkout(req);
    emit(SaveWorkoutSuccess(resp));
  }

  int _estimateRestTime(List sets) {
    return 60;
  }
}
