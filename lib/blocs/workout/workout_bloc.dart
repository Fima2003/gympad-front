import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/personal_workout.dart';
import '../../models/workout.dart';
import '../../services/workout_service.dart';
import '../../services/global_timer_service.dart';
import '../../services/logger_service.dart';
import '../../services/api/workout_api_service.dart';
import '../../services/hive/personal_workout_lss.dart';

part 'workout_events.dart';
part 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutService _workoutService = WorkoutService();
  final GlobalTimerService _timerService = GlobalTimerService();
  final AppLogger _logger = AppLogger();
  final WorkoutApiService _workoutApi = WorkoutApiService();
  final PersonalWorkoutLocalService _personalLocal =
      PersonalWorkoutLocalService();

  WorkoutBloc() : super(WorkoutInitial()) {
    on<WorkoutLoaded>(_onWorkoutLoaded);
    on<WorkoutStarted>(_onWorkoutStarted);
    on<WorkoutFinished>(_onWorkoutFinished);
    on<ExerciseAdded>(_onExerciseAdded);
    on<ExerciseFinished>(_onExerciseFinished);
    on<SetAdded>(_onSetAdded);
    on<WorkoutHistoryRequested>(_onWorkoutHistoryRequested);
    on<PersonalWorkoutsSyncRequested>(_onPersonalWorkoutsSyncRequested);
  }

  Future<void> _onWorkoutLoaded(
    WorkoutLoaded event,
    Emitter<WorkoutState> emit,
  ) async {
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

  Future<void> _onWorkoutStarted(
    WorkoutStarted event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      await _workoutService.startWorkout(event.type, name: event.name);
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

  Future<void> _onWorkoutFinished(
    WorkoutFinished event,
    Emitter<WorkoutState> emit,
  ) async {
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

  Future<void> _onExerciseAdded(
    ExerciseAdded event,
    Emitter<WorkoutState> emit,
  ) async {
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

  Future<void> _onExerciseFinished(
    ExerciseFinished event,
    Emitter<WorkoutState> emit,
  ) async {
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

  Future<void> _onPersonalWorkoutsSyncRequested(
    PersonalWorkoutsSyncRequested event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      final resp = await _workoutApi.getPersonalWorkouts();
      if (resp.success && resp.data != null) {
        final list = resp.data!;
        await _personalLocal.saveAll(list);
        emit(
          PersonalWorkoutsLoaded(
            list.map((e) => PersonalWorkout.fromResponse(e)).toList(),
          ),
        );
      } else {
        // Fallback to local cache on failure
        final cached = await _personalLocal.loadAll();
        emit(PersonalWorkoutsLoaded(cached));
      }
    } catch (e, st) {
      _logger.error('Failed to sync personal workouts', e, st);
      final cached = await _personalLocal.loadAll();
      emit(PersonalWorkoutsLoaded(cached));
    }
  }
}
