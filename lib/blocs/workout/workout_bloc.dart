import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/custom_workout.dart';
import '../../models/workout.dart';
import '../../models/workout_set.dart';
import '../../services/workout_service.dart';
import '../../services/logger_service.dart';

part 'workout_events.dart';
part 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutService _workoutService = WorkoutService();
  final AppLogger _logger = AppLogger();
  Timer? _phaseTimer; // shared timer for set/rest phases
  Duration _currentSetElapsed = Duration.zero;
  Duration _currentRestRemaining = Duration.zero;
  Duration _currentRestTotal = Duration.zero;
  bool _restPaused =
      false; // pause flag for rest phase (free workout selection)

  WorkoutBloc() : super(WorkoutInitial()) {
    on<WorkoutLoaded>(_onWorkoutLoaded);
    on<WorkoutStarted>(_onWorkoutStarted);
    on<WorkoutCancelled>(_onWorkoutCancelled);
    on<WorkoutFinished>(_onWorkoutFinished);
    on<ExerciseAdded>(_onExerciseAdded);
    on<SetAdded>(_onSetAdded);
    on<WorkoutHistoryRequested>(_onWorkoutHistoryRequested);
    on<UpcomingExercisesReordered>(_onUpcomingExercisesReordered);
    // New run-phase events
    on<RunEnterSet>(_onRunEnterSet);
    on<RunEnterRest>(_onRunEnterRest);
    on<RunSetTick>(_onRunSetTick);
    on<RunRestTick>(_onRunRestTick);
    on<RunFinishCurrent>(_onRunFinishCurrent);
    on<RunSkipRest>(_onRunSkipRest);
    on<RunExtendRest>(_onRunExtendRest);
    on<RunFinishEarly>(_onRunFinishEarly);
    on<RunPauseRest>(_onRunPauseRest);
    on<RunResumeRest>(_onRunResumeRest);
    // Free workout consolidated UI intent
    on<FreeWorkoutFocusExercise>(_onFreeWorkoutFocusExercise);
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
        add(const RunEnterSet());
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
    // Allow reorder during legacy in-progress or new rest phase.
    if (state is! WorkoutInProgress && state is! WorkoutRunRest) return;
    // If in new rest state, ensure we don't reorder locked (active) exercise.
    if (state is WorkoutRunRest) {
      final s = state as WorkoutRunRest;
      if (event.startIndex < s.reorderStartIndex) {
        return; // ignore invalid reorder attempting to move locked exercise
      }
    }
    _workoutService.reorderUpcomingExercises(
      event.startIndex,
      event.newOrderIds,
    );

    // Always update legacy state if present
    final currentWorkout = _workoutService.currentWorkout;
    final workoutToFollow = _workoutService.workoutToFollow;
    if (currentWorkout != null && state is WorkoutInProgress) {
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

    // If currently in rest phase (new state), refresh upcoming list.
    if (state is WorkoutRunRest && currentWorkout != null) {
      final s = state as WorkoutRunRest;
      final plan = workoutToFollow;
      final upcoming =
          plan == null
              ? <CustomWorkoutExercise>[]
              : plan.exercises.skip(s.reorderStartIndex).toList();
      // Recompute nextExercise if we are between exercises (i.e., just finished previous)
      CustomWorkoutExercise? newNext = s.nextExercise;
      if (plan != null) {
        final betweenExercises =
            currentWorkout.exercises.length == s.currentExerciseIdx &&
            s.currentExerciseIdx < plan.exercises.length;
        if (betweenExercises) {
          newNext = plan.exercises[s.currentExerciseIdx];
        }
      }
      emit(
        WorkoutRunRest(
          workout: currentWorkout,
          workoutToFollow: plan,
          currentExercise: s.currentExercise,
          currentExerciseIdx: s.currentExerciseIdx,
          currentSetIdx: s.currentSetIdx,
          remaining: _currentRestRemaining,
          total: _currentRestTotal,
          nextExercise: newNext,
          progress: s.progress,
          upcomingReorderable: upcoming,
          reorderStartIndex: s.reorderStartIndex,
          isFinishing: s.isFinishing,
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
        add(const RunEnterSet());
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
          event.reps,
          event.weight,
          event.duration,
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
        add(const RunEnterSet());
      }
    } catch (e, st) {
      _logger.error('Failed to add exercise', e, st);
      emit(WorkoutError('Failed to add exercise'));
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

  // ---------------------------------------------------------------------------
  // New run-phase handlers
  // ---------------------------------------------------------------------------
  void _cancelTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
  }

  void _startSetTicker() {
    _cancelTimer();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const RunSetTick());
    });
  }

  void _startRestTicker() {
    _cancelTimer();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const RunRestTick());
    });
  }

  Future<void> _onRunEnterSet(
    RunEnterSet event,
    Emitter<WorkoutState> emit,
  ) async {
    // Whenever we enter a set phase, ensure rest pause flag is cleared
    _restPaused = false;
    var currentWorkout = _workoutService.currentWorkout;
    final workoutToFollow = _workoutService.workoutToFollow;
    if (currentWorkout == null) return;

    // Determine indexes
    final exerciseIdx = _workoutService.getExerciseIdx();
    final setIdx = _workoutService.getSetIdx();
    // If following a template, choose planned exercise or fallback to last performed.
    CustomWorkoutExercise? plannedExercise;
    if (workoutToFollow != null &&
        exerciseIdx < workoutToFollow.exercises.length) {
      plannedExercise = workoutToFollow.exercises[exerciseIdx];
    } else if (workoutToFollow != null &&
        exerciseIdx >= workoutToFollow.exercises.length) {
      // generally speaking, should not happen
      // Completed all planned exercises -> finishing state
      emit(WorkoutRunFinishing(currentWorkout));
      add(const WorkoutFinished());
      return;
    }

    if (plannedExercise == null) {
      // Free workout case: we must have at least one exercise added to start a set
      if (currentWorkout.exercises.isEmpty) return; // nothing yet
      // For free workout we use the current real exercise as planned exercise surrogate
      final realExercise = currentWorkout.exercises.last;
      plannedExercise = CustomWorkoutExercise(
        id: realExercise.exerciseId,
        name: realExercise.name,
        setsAmount: realExercise.sets.length + 1, // unknown future
        restTime: 60,
        suggestedReps: null,
        suggestedWeight: null,
      );
    }

    // Ensure an actual workout exercise exists for this planned exercise in the real workout list.
    // When starting a planned workout, before the first set of a planned exercise, the workout
    // may not yet contain that exercise entry. We auto-add a basic exercise record so that
    // subsequent set additions attach properly.
    final needsCreation =
        currentWorkout.exercises.isEmpty ||
        (workoutToFollow != null &&
            currentWorkout.exercises.length <= exerciseIdx);
    if (needsCreation) {
      try {
        await _workoutService.addExercise(
          plannedExercise.id,
          plannedExercise
              .id, // placeholder name (can be enriched via DataBloc externally)
          'general',
        );
        currentWorkout = _workoutService.currentWorkout;
        if (currentWorkout == null) return; // safety
      } catch (e, st) {
        _logger.error(
          'Failed to auto-add exercise ${plannedExercise.id}',
          e,
          st,
        );
        emit(const WorkoutError('Failed to initialize exercise'));
        return;
      }
    }

    _currentSetElapsed = Duration.zero;
    _startSetTicker();

    // Determine run finish type
    RunFinishType finishType;
    if (workoutToFollow == null) {
      // Free workout: always treat finish as completing a single set.
      // Finishing the entire workout is done explicitly via RunFinishEarly (from rest) in free mode.
      finishType = RunFinishType.set;
    } else {
      final completedSetsForCurrent =
          currentWorkout.exercises.isEmpty
              ? 0
              : currentWorkout.exercises.last.sets.length;
      final totalSetsPlanned = plannedExercise.setsAmount;
      if (completedSetsForCurrent < totalSetsPlanned - 1) {
        finishType = RunFinishType.set;
      } else if (exerciseIdx < workoutToFollow.exercises.length - 1) {
        finishType = RunFinishType.exercise;
      } else {
        finishType = RunFinishType.workout;
      }
    }

    final completedSetsList =
        currentWorkout.exercises.isEmpty
            ? <WorkoutSet>[]
            : currentWorkout.exercises.last.sets;

    emit(
      WorkoutRunInSet(
        workout: currentWorkout,
        workoutToFollow: workoutToFollow,
        currentExercise: plannedExercise,
        currentExerciseIdx: exerciseIdx,
        currentSetIdx: setIdx,
        completedSets: completedSetsList,
        elapsed: _currentSetElapsed,
        finishType: finishType,
      ),
    );
  }

  Future<void> _onRunSetTick(
    RunSetTick event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is! WorkoutRunInSet) return;
    _currentSetElapsed += const Duration(seconds: 1);
    final s = state as WorkoutRunInSet;
    emit(
      WorkoutRunInSet(
        workout: s.workout,
        workoutToFollow: s.workoutToFollow,
        currentExercise: s.currentExercise,
        currentExerciseIdx: s.currentExerciseIdx,
        currentSetIdx: s.currentSetIdx,
        completedSets: s.completedSets,
        elapsed: _currentSetElapsed,
        finishType: s.finishType,
      ),
    );
  }

  Future<void> _onRunFinishCurrent(
    RunFinishCurrent event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is! WorkoutRunInSet) return;
    final s = state as WorkoutRunInSet;
    try {
      switch (s.finishType) {
        case RunFinishType.set:
          await _workoutService.addSetToCurrentExercise(
            event.reps,
            event.weight,
            event.duration,
          );
          // Enter rest before next set of the same exercise
          final restSeconds = s.currentExercise.restTime;
          add(RunEnterRest(Duration(seconds: restSeconds)));
          break;
        case RunFinishType.exercise:
          await _workoutService.finishCurrentExercise(
            event.reps,
            event.weight,
            event.duration,
          );
          final restSeconds =
              s.currentExercise.restTime; // Could vary per exercise
          add(RunEnterRest(Duration(seconds: restSeconds)));
          break;
        case RunFinishType.workout:
          _cancelTimer();
          emit(WorkoutRunFinishing(s.workout));
          final finished = await _workoutService.finishWorkout(
            event.reps,
            event.weight,
            event.duration,
          );
          if (finished != null) {
            emit(WorkoutCompleted(finished));
          } else {
            emit(const WorkoutError('Failed to finish workout'));
          }
          break;
      }
    } catch (e, st) {
      _logger.error('Failed RunFinishCurrent', e, st);
      emit(const WorkoutError('Failed to finish current segment'));
    }
  }

  Future<void> _onRunEnterRest(
    RunEnterRest event,
    Emitter<WorkoutState> emit,
  ) async {
    // Reset pause flag because a fresh rest starts now
    _restPaused = false;
    final w = _workoutService.currentWorkout;
    final plan = _workoutService.workoutToFollow;
    if (w == null) return;
    _cancelTimer();
    _currentRestTotal = event.restDuration;
    _currentRestRemaining = event.restDuration;
    _startRestTicker();

    final exerciseIdx = _workoutService.getExerciseIdx();
    final setIdx = _workoutService.getSetIdx();
    // Determine whether we are between exercises (finished previous) or between sets of current.
    final betweenExercises =
        w.exercises.length == exerciseIdx && exerciseIdx > 0;
    CustomWorkoutExercise currentPlanned;
    CustomWorkoutExercise? nextExercise;
    if (plan != null) {
      if (betweenExercises) {
        // Current exercise is the one just completed (exerciseIdx - 1), next is at exerciseIdx (if exists)
        currentPlanned = plan.exercises[exerciseIdx - 1];
        if (exerciseIdx < plan.exercises.length) {
          nextExercise = plan.exercises[exerciseIdx];
        }
      } else if (exerciseIdx < plan.exercises.length) {
        // Rest between sets inside current exercise
        currentPlanned = plan.exercises[exerciseIdx];
        nextExercise = plan.exercises[exerciseIdx]; // Same exercise continues
      } else {
        // Fallback if out of range
        currentPlanned = CustomWorkoutExercise(
          id: w.exercises.isNotEmpty ? w.exercises.last.exerciseId : 'unknown',
          name: w.exercises.isNotEmpty ? w.exercises.last.name : 'Unknown',
          setsAmount: 1,
          restTime: 60,
          suggestedReps: null,
          suggestedWeight: null,
        );
      }
    } else {
      // Free workout fallback
      currentPlanned = CustomWorkoutExercise(
        id: w.exercises.isNotEmpty ? w.exercises.last.exerciseId : 'unknown',
        name: w.exercises.isNotEmpty ? w.exercises.last.name : 'Unknown',
        setsAmount: 1,
        restTime: 60,
        suggestedReps: null,
        suggestedWeight: null,
      );
    }
    final progress = _workoutService.getPercentageDone() ?? 0;

    // Reorder slice determination: lock active exercise if we are mid-exercise (not between exercises and exercise has started sets)
    int reorderStartIndex = exerciseIdx;
    if (!betweenExercises) {
      // mid-exercise if the real workout already has at least one set for this exercise
      final activeExerciseStarted =
          w.exercises.length > exerciseIdx &&
          w.exercises[exerciseIdx].sets.isNotEmpty;
      if (activeExerciseStarted) {
        reorderStartIndex =
            exerciseIdx + 1; // exclude active exercise from reorderable slice
      }
    }
    if (plan != null && reorderStartIndex > plan.exercises.length) {
      reorderStartIndex = plan.exercises.length; // clamp
    }
    final upcoming =
        plan == null
            ? <CustomWorkoutExercise>[]
            : plan.exercises.skip(reorderStartIndex).toList();

    emit(
      WorkoutRunRest(
        workout: w,
        workoutToFollow: plan,
        currentExercise: currentPlanned,
        currentExerciseIdx: exerciseIdx,
        currentSetIdx: setIdx,
        remaining: _currentRestRemaining,
        total: _currentRestTotal,
        nextExercise: nextExercise,
        progress: progress,
        upcomingReorderable: upcoming,
        reorderStartIndex: reorderStartIndex,
        isFinishing: false,
      ),
    );
  }

  Future<void> _onRunRestTick(
    RunRestTick event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is! WorkoutRunRest) return;
    if (_restPaused) return; // do not tick while paused
    if (_currentRestRemaining > Duration.zero) {
      _currentRestRemaining -= const Duration(seconds: 1);
    }
    final s = state as WorkoutRunRest;
    if (_currentRestRemaining <= Duration.zero) {
      // Auto transition to set
      add(const RunEnterSet());
      return;
    }
    emit(
      WorkoutRunRest(
        workout: s.workout,
        workoutToFollow: s.workoutToFollow,
        currentExercise: s.currentExercise,
        currentExerciseIdx: s.currentExerciseIdx,
        currentSetIdx: s.currentSetIdx,
        remaining: _currentRestRemaining,
        total: _currentRestTotal,
        nextExercise: s.nextExercise,
        progress: s.progress,
        upcomingReorderable: s.upcomingReorderable,
        reorderStartIndex: s.reorderStartIndex,
        isFinishing: s.isFinishing,
      ),
    );
  }

  Future<void> _onRunSkipRest(
    RunSkipRest event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is! WorkoutRunRest) return;
    add(const RunEnterSet());
  }

  Future<void> _onRunExtendRest(
    RunExtendRest event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is! WorkoutRunRest) return;
    _currentRestRemaining += Duration(seconds: event.seconds);
    _currentRestTotal += Duration(seconds: event.seconds);
    final s = state as WorkoutRunRest;
    emit(
      WorkoutRunRest(
        workout: s.workout,
        workoutToFollow: s.workoutToFollow,
        currentExercise: s.currentExercise,
        currentExerciseIdx: s.currentExerciseIdx,
        currentSetIdx: s.currentSetIdx,
        remaining: _currentRestRemaining,
        total: _currentRestTotal,
        nextExercise: s.nextExercise,
        progress: s.progress,
        upcomingReorderable: s.upcomingReorderable,
        reorderStartIndex: s.reorderStartIndex,
        isFinishing: s.isFinishing,
      ),
    );
  }

  Future<void> _onRunPauseRest(
    RunPauseRest event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is! WorkoutRunRest) return;
    if (_restPaused) return;
    _restPaused = true;
    _cancelTimer();
    final s = state as WorkoutRunRest;
    emit(
      WorkoutRunRest(
        workout: s.workout,
        workoutToFollow: s.workoutToFollow,
        currentExercise: s.currentExercise,
        currentExerciseIdx: s.currentExerciseIdx,
        currentSetIdx: s.currentSetIdx,
        remaining: _currentRestRemaining,
        total: _currentRestTotal,
        nextExercise: s.nextExercise,
        progress: s.progress,
        upcomingReorderable: s.upcomingReorderable,
        reorderStartIndex: s.reorderStartIndex,
        isFinishing: s.isFinishing,
      ),
    );
  }

  Future<void> _onRunResumeRest(
    RunResumeRest event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is! WorkoutRunRest) return;
    if (!_restPaused) return;
    _restPaused = false;
    _startRestTicker();
    final s = state as WorkoutRunRest;
    emit(
      WorkoutRunRest(
        workout: s.workout,
        workoutToFollow: s.workoutToFollow,
        currentExercise: s.currentExercise,
        currentExerciseIdx: s.currentExerciseIdx,
        currentSetIdx: s.currentSetIdx,
        remaining: _currentRestRemaining,
        total: _currentRestTotal,
        nextExercise: s.nextExercise,
        progress: s.progress,
        upcomingReorderable: s.upcomingReorderable,
        reorderStartIndex: s.reorderStartIndex,
        isFinishing: s.isFinishing,
      ),
    );
  }

  Future<void> _onRunFinishEarly(
    RunFinishEarly event,
    Emitter<WorkoutState> emit,
  ) async {
    // Only allowed during rest according to updated requirement.
    if (state is! WorkoutRunRest) return;
    final w = _workoutService.currentWorkout;
    if (w == null) return;
    _cancelTimer();
    emit(WorkoutRunFinishing(w));
    try {
      final finished = await _workoutService.finishWorkout(null, null, null);
      if (finished != null) {
        emit(WorkoutCompleted(finished));
      } else {
        emit(const WorkoutError('Failed to finish workout early'));
      }
    } catch (e, st) {
      _logger.error('Failed early finish', e, st);
      emit(const WorkoutError('Failed to finish workout early'));
    }
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
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

  // ---------------------------------------------------------------------------
  // Free workout consolidated handler
  // ---------------------------------------------------------------------------
  Future<void> _onFreeWorkoutFocusExercise(
    FreeWorkoutFocusExercise event,
    Emitter<WorkoutState> emit,
  ) async {
    // If a planned workout is active, ignore (feature reserved for free mode only)
    if (_workoutService.workoutToFollow != null) {
      return;
    }

    // Ensure workout started
    if (_workoutService.currentWorkout == null ||
        !(_workoutService.currentWorkout?.isOngoing ?? false)) {
      add(WorkoutStarted(WorkoutType.free));
      // Defer adding exercise until workout start completes; queue an ExerciseAdded
      add(
        ExerciseAdded(
          exerciseId: event.exerciseId,
          name: event.name,
          muscleGroup: event.muscleGroup,
          equipmentId: event.equipmentId,
        ),
      );
      return; // RunEnterSet will be triggered by _onExerciseAdded
    }

    final w = _workoutService.currentWorkout;
    if (w == null) return; // safety

    // Check if exercise already present
    final existingIndex = w.exercises.indexWhere(
      (ex) => ex.exerciseId == event.exerciseId,
    );

    final isRestPhase = state is WorkoutRunRest;
    final isSetPhase = state is WorkoutRunInSet;

    if (existingIndex == -1) {
      // Add new exercise then let normal add logic trigger RunEnterSet
      add(
        ExerciseAdded(
          exerciseId: event.exerciseId,
          name: event.name,
          muscleGroup: event.muscleGroup,
          equipmentId: event.equipmentId,
        ),
      );
      return;
    }

    final isLast = existingIndex == w.exercises.length - 1;

    if (!isLast) {
      // Re-add to move it to last position (service implementation handles reposition)
      add(
        ExerciseAdded(
          exerciseId: event.exerciseId,
          name: event.name,
          muscleGroup: event.muscleGroup,
          equipmentId: event.equipmentId,
        ),
      );
      // After reordering we want to immediately enter the set phase. If currently resting we skip rest first.
      if (isRestPhase) {
        add(const RunSkipRest());
      } else if (!isSetPhase) {
        add(const RunEnterSet());
      }
      return;
    }

    // Already last/current exercise.
    if (isRestPhase) {
      // Skip rest to immediately begin a new set.
      add(const RunSkipRest());
    } else if (!isSetPhase) {
      add(const RunEnterSet());
    } // if already in set phase, do nothing.
  }
}
