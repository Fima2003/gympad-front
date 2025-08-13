import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/global_timer_service.dart';
import '../services/logger_service.dart';

part 'workout_events.dart';
part 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutService _workoutService = WorkoutService();
  final GlobalTimerService _timerService = GlobalTimerService();
  final AppLogger _logger = AppLogger();

  WorkoutBloc() : super(WorkoutInitial()) {
    on<WorkoutLoaded>(_onWorkoutLoaded);
    on<WorkoutStarted>(_onWorkoutStarted);
    on<WorkoutFinished>(_onWorkoutFinished);
    on<ExerciseAdded>(_onExerciseAdded);
    on<ExerciseFinished>(_onExerciseFinished);
    on<SetAdded>(_onSetAdded);
    on<WorkoutHistoryRequested>(_onWorkoutHistoryRequested);
  }

  Future<void> _onWorkoutLoaded(WorkoutLoaded event, Emitter<WorkoutState> emit) async {
    emit(WorkoutLoading());
    try {
      await _workoutService.loadCurrentWorkout();
      unawaited(_workoutService.uploadPendingWorkouts());
      
      final currentWorkout = _workoutService.currentWorkout;
      if (currentWorkout != null && currentWorkout.isOngoing) {
        emit(WorkoutInProgress(currentWorkout));
      } else {
        emit(WorkoutInitial());
      }
    } catch (e, st) {
      _logger.error('Failed to load workout', e, st);
      emit(WorkoutError('Failed to load workout'));
    }
  }

  Future<void> _onWorkoutStarted(WorkoutStarted event, Emitter<WorkoutState> emit) async {
    try {
      await _workoutService.startWorkout(name: event.name);
      _timerService.start();
      
      final currentWorkout = _workoutService.currentWorkout;
      if (currentWorkout != null) {
        emit(WorkoutInProgress(currentWorkout));
      }
    } catch (e, st) {
      _logger.error('Failed to start workout', e, st);
      emit(WorkoutError('Failed to start workout'));
    }
  }

  Future<void> _onWorkoutFinished(WorkoutFinished event, Emitter<WorkoutState> emit) async {
    try {
      final currentWorkout = _workoutService.currentWorkout;
      if (currentWorkout != null) {
        await _workoutService.finishWorkout();
        _timerService.stop();
        
        emit(WorkoutCompleted(currentWorkout));
      }
    } catch (e, st) {
      _logger.error('Failed to finish workout', e, st);
      emit(WorkoutError('Failed to finish workout'));
    }
  }

  Future<void> _onExerciseAdded(ExerciseAdded event, Emitter<WorkoutState> emit) async {
    try {
      await _workoutService.addExercise(
        event.exerciseId,
        event.name,
        event.muscleGroup,
        equipmentId: event.equipmentId,
      );
      
      final currentWorkout = _workoutService.currentWorkout;
      if (currentWorkout != null) {
        emit(WorkoutInProgress(currentWorkout));
      }
    } catch (e, st) {
      _logger.error('Failed to add exercise', e, st);
      emit(WorkoutError('Failed to add exercise'));
    }
  }

  Future<void> _onExerciseFinished(ExerciseFinished event, Emitter<WorkoutState> emit) async {
    try {
      await _workoutService.finishCurrentExercise();
      
      final currentWorkout = _workoutService.currentWorkout;
      if (currentWorkout != null) {
        emit(WorkoutInProgress(currentWorkout));
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
      if (currentWorkout != null) {
        emit(WorkoutInProgress(currentWorkout));
      }
    } catch (e, st) {
      _logger.error('Failed to add set', e, st);
      emit(WorkoutError('Failed to add set'));
    }
  }

  Future<void> _onWorkoutHistoryRequested(WorkoutHistoryRequested event, Emitter<WorkoutState> emit) async {
    try {
      final workouts = await _workoutService.getWorkoutHistory();
      emit(WorkoutHistoryLoaded(workouts));
    } catch (e, st) {
      _logger.error('Failed to load workout history', e, st);
      emit(WorkoutError('Failed to load workout history'));
    }
  }
}
