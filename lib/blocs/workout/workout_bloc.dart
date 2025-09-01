import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/custom_workout.dart';
import '../../models/workout.dart';
import '../../services/workout_service.dart';
import '../../services/logger_service.dart';

part 'workout_events.dart';
part 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutService _workoutService = WorkoutService();
  final AppLogger _logger = AppLogger();

  WorkoutBloc() : super(WorkoutInitial()) {
    on<WorkoutLoaded>(_onWorkoutLoaded);
    on<WorkoutStarted>(_onWorkoutStarted);
    on<WorkoutCancelled>(_onWorkoutCancelled);
    on<WorkoutFinished>(_onWorkoutFinished);
    on<ExerciseAdded>(_onExerciseAdded);
    on<ExerciseFinished>(_onExerciseFinished);
    on<SetAdded>(_onSetAdded);
    on<WorkoutHistoryRequested>(_onWorkoutHistoryRequested);
  on<UpcomingExercisesReordered>(_onUpcomingExercisesReordered);
  }

  Future<void> _onWorkoutLoaded(
    WorkoutLoaded event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(WorkoutLoading());
    try {
      await _workoutService.loadCurrentWorkout();
      await _workoutService.loadWorkoutToFollow();
      unawaited(_workoutService.uploadPendingWorkouts());

      final currentWorkout = _workoutService.currentWorkout;
      final workoutToFollow = _workoutService.workoutToFollow;
      if (currentWorkout != null && currentWorkout.isOngoing) {
        emit(
          WorkoutInProgress(
            currentWorkout,
            workoutToFollow: workoutToFollow,
            currentExerciseIdx: _workoutService.getExerciseIdx(),
            currentSetIdx: _workoutService.getSetIdx(),
            progress: _workoutService.getPercentageDone(),
          ),
        );
      } else {
        emit(WorkoutInitial());
      }
    } catch (e, st) {
      _logger.error('Failed to load workout', e, st);
      emit(WorkoutError('Failed to load workout'));
    }
  }

  Future<void> _onUpcomingExercisesReordered(
    UpcomingExercisesReordered event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is! WorkoutInProgress) return;
    _workoutService.reorderUpcomingExercises(event.startIndex, event.newOrderIds);
    final currentWorkout = _workoutService.currentWorkout;
    final workoutToFollow = _workoutService.workoutToFollow;
    if (currentWorkout != null) {
      emit(
        WorkoutInProgress(
          currentWorkout,
          workoutToFollow: workoutToFollow,
          currentExerciseIdx: _workoutService.getExerciseIdx(),
          currentSetIdx: _workoutService.getSetIdx(),
          progress: _workoutService.getPercentageDone(),
        ),
      );
    }
  }

  Future<void> _onWorkoutStarted(
    WorkoutStarted event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      emit(WorkoutLoading());
      await _workoutService.startWorkout(
        event.type,
        workoutToFollow: event.workoutToFollow,
      );

      final currentWorkout = _workoutService.currentWorkout;
      final workoutToFollow = _workoutService.workoutToFollow;
      if (currentWorkout != null) {
        emit(
          WorkoutInProgress(
            currentWorkout,
            workoutToFollow: workoutToFollow,
            currentExerciseIdx: _workoutService.getExerciseIdx(),
            currentSetIdx: _workoutService.getSetIdx(),
            progress: _workoutService.getPercentageDone(),
          ),
        );
      }
    } catch (e, st) {
      _logger.error('Failed to start workout', e, st);
      emit(WorkoutError('Failed to start workout'));
    }
  }

  Future<void> _onWorkoutCancelled(
    WorkoutCancelled event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      await _workoutService.cancelWorkout();
      emit(WorkoutInitial());
    } catch (e, st) {
      _logger.error('Failed to cancel workout', e, st);
      emit(WorkoutError('Failed to cancel workout'));
    }
  }

  Future<void> _onWorkoutFinished(
    WorkoutFinished event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      // emit(WorkoutLoading());
      final currentWorkout = _workoutService.currentWorkout;
      if (currentWorkout != null) {
        await _workoutService.finishWorkout(
          event.reps, event.weight, event.duration
        );

        emit(WorkoutCompleted(currentWorkout));
      }
    } catch (e, st) {
      _logger.error('Failed to finish workout', e, st);
      emit(WorkoutError('Failed to finish workout'));
    }
  }

  Future<void> _onExerciseAdded(
    ExerciseAdded event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      emit(AddingExercise());
      await _workoutService.addExercise(
        event.exerciseId,
        event.name,
        event.muscleGroup,
        equipmentId: event.equipmentId,
      );

      final currentWorkout = _workoutService.currentWorkout;
      final workoutToFollow = _workoutService.workoutToFollow;
      if (currentWorkout != null) {
        emit(
          WorkoutInProgress(
            currentWorkout,
            workoutToFollow: workoutToFollow,
            currentExerciseIdx: _workoutService.getExerciseIdx(),
            currentSetIdx: _workoutService.getSetIdx(),
            progress: _workoutService.getPercentageDone(),
          ),
        );
      }
    } catch (e, st) {
      _logger.error('Failed to add exercise', e, st);
      emit(WorkoutError('Failed to add exercise'));
    }
  }

  Future<void> _onExerciseFinished(
    ExerciseFinished event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      await _workoutService.finishCurrentExercise(
        event.reps,
        event.weight,
        event.duration,
      );

      final currentWorkout = _workoutService.currentWorkout;
      final workoutToFollow = _workoutService.workoutToFollow;
      if (currentWorkout != null) {
        emit(
          WorkoutInProgress(
            currentWorkout,
            workoutToFollow: workoutToFollow,
            currentExerciseIdx: _workoutService.getExerciseIdx(),
            currentSetIdx: _workoutService.getSetIdx(),
            progress: _workoutService.getPercentageDone(),
          ),
        );
      }
    } catch (e, st) {
      _logger.error('Failed to finish exercise', e, st);
      emit(WorkoutError('Failed to finish exercise'));
    }
  }

  Future<void> _onSetAdded(SetAdded event, Emitter<WorkoutState> emit) async {
    try {
      await _workoutService.addSetToCurrentExercise(
        event.reps,
        event.weight,
        event.duration,
      );

      final currentWorkout = _workoutService.currentWorkout;
      final workoutToFollow = _workoutService.workoutToFollow;
      if (currentWorkout != null) {
        emit(
          WorkoutInProgress(
            currentWorkout,
            workoutToFollow: workoutToFollow,
            currentExerciseIdx: _workoutService.getExerciseIdx(),
            currentSetIdx: _workoutService.getSetIdx(),
            progress: _workoutService.getPercentageDone(),
          ),
        );
      }
    } catch (e, st) {
      _logger.error('Failed to add set', e, st);
      emit(WorkoutError('Failed to add set'));
    }
  }

  Future<void> _onWorkoutHistoryRequested(
    WorkoutHistoryRequested event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      final workouts = await _workoutService.getWorkoutHistory();
      emit(WorkoutHistoryLoaded(workouts));
    } catch (e, st) {
      _logger.error('Failed to load workout history', e, st);
      emit(WorkoutError('Failed to load workout history'));
    }
  }
}
