import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/global_timer_service.dart';
import '../services/logger_service.dart';

// Events
abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();
  
  @override
  List<Object?> get props => [];
}

class WorkoutStarted extends WorkoutEvent {}

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

// States
abstract class WorkoutState extends Equatable {
  const WorkoutState();
  
  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class WorkoutInProgress extends WorkoutState {
  final Workout workout;
  
  const WorkoutInProgress(this.workout);
  
  @override
  List<Object> get props => [workout];
}

class WorkoutCompleted extends WorkoutState {
  final Workout workout;
  
  const WorkoutCompleted(this.workout);
  
  @override
  List<Object> get props => [workout];
}

class WorkoutError extends WorkoutState {
  final String message;
  
  const WorkoutError(this.message);
  
  @override
  List<Object> get props => [message];
}

class WorkoutHistoryLoaded extends WorkoutState {
  final List<Workout> workouts;
  
  const WorkoutHistoryLoaded(this.workouts);
  
  @override
  List<Object> get props => [workouts];
}

// Bloc
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
      await _workoutService.startWorkout();
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
