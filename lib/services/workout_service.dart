import 'dart:async';

import '../models/custom_workout.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/api/api.dart';
import '../services/logger_service.dart';
import 'hive/current_workout_lss.dart';
import 'hive/workout_history_lss.dart';

enum WorkoutType { custom, free, personal }

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  final AppLogger _logger = AppLogger();
  final WorkoutApiService _workoutApiService = WorkoutApiService();

  Workout? _currentWorkout;
  Workout? get currentWorkout => _currentWorkout;

  CustomWorkout? _workoutToFollow;
  CustomWorkout? get workoutToFollow => _workoutToFollow;

  final _currentWorkoutStorage = CurrentWorkoutLocalStorageService();
  final _historyStorage = WorkoutHistoryLocalStorageService();

  Future<void> startWorkout(
    WorkoutType type, {
    CustomWorkout? workoutToFollow,
  }) async {
    if (_currentWorkout != null && _currentWorkout!.isOngoing) {
      _logger.warning('Workout already in progress. Rewriting');
      _currentWorkout = null;
      _workoutToFollow = null;
    }

    _currentWorkout = Workout(
      id:
          "${type == WorkoutType.free ? 'free' : 'custom'}_${DateTime.now().millisecondsSinceEpoch.toString()}",
      name: workoutToFollow?.name,
      exercises: [],
      startTime: DateTime.now(),
    );

    _workoutToFollow = workoutToFollow?.copyWith();

    await _saveCurrentWorkout();
    await _saveWorkoutToFollow();
    _logger.info('New workout started with ID: ${_currentWorkout!.id}');
  }

  Future<void> cancelWorkout() async {
    if (_currentWorkout == null) {
      _logger.error('No current workout to cancel');
      return;
    }

    _currentWorkout = null;
    _workoutToFollow = null;

    await _saveCurrentWorkout();
    await _saveWorkoutToFollow();
    _logger.info('Workout cancelled');
  }

  Future<void> addExercise(
    String exerciseId,
    String name,
    String muscleGroup, {
    String? equipmentId,
  }) async {
    if (_currentWorkout == null || !_currentWorkout!.isOngoing) {
      await startWorkout(WorkoutType.free);
    }

    // Check if exercise already exists in current workout
    final existingIndex = _currentWorkout!.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );

    if (existingIndex != -1) {
      // Make the existing exercise the current (last) one so sets append correctly
      final exercises = [..._currentWorkout!.exercises];
      final existing = exercises.removeAt(existingIndex);
      exercises.add(existing);

      _currentWorkout = _currentWorkout!.copyWith(exercises: exercises);
      unawaited(_saveCurrentWorkout());
      _logger.info('Exercise $name already exists — set as current exercise');
      return;
    }

    final workoutExercise = WorkoutExercise(
      exerciseId: exerciseId,
      name: name,
      equipmentId: equipmentId,
      muscleGroup: muscleGroup,
      sets: [],
      startTime: DateTime.now(),
    );

    _currentWorkout = _currentWorkout!.copyWith(
      exercises: [..._currentWorkout!.exercises, workoutExercise],
    );

    await _saveCurrentWorkout();
    _logger.info('Added exercise $name to workout');
  }

  Future<void> addSetToCurrentExercise(
    int reps,
    double weight,
    Duration duration,
  ) async {
    if (_currentWorkout == null || _currentWorkout!.exercises.isEmpty) {
      _logger.error('No current exercise to add set to');
      return;
    }

    final currentExerciseIndex = _currentWorkout!.exercises.length - 1;
    final currentExercise = _currentWorkout!.exercises[currentExerciseIndex];

    final newSet = WorkoutSet(
      setNumber: currentExercise.sets.length + 1,
      reps: reps,
      weight: weight,
      time: duration,
    );

    final updatedSets = [...currentExercise.sets, newSet];
    final updatedExercise = currentExercise.copyWith(sets: updatedSets);

    List<WorkoutExercise> updatedExercises = [..._currentWorkout!.exercises];
    updatedExercises[currentExerciseIndex] = updatedExercise;

    _currentWorkout = _currentWorkout!.copyWith(exercises: updatedExercises);

    unawaited(_saveCurrentWorkout());
    _logger.info('Added set to exercise ${currentExercise.name}');
  }

  Future<void> finishCurrentExercise(
    int reps,
    double weight,
    Duration duration,
  ) async {
    if (_currentWorkout == null || _currentWorkout!.exercises.isEmpty) {
      _logger.error('No current exercise to finish');
      return;
    }
    await addSetToCurrentExercise(reps, weight, duration);
    final currentExercise = _currentWorkout!.exercises.last;

    if (currentExercise.endTime != null) {
      _logger.warning('Exercise already finished');
      return;
    }

    List<WorkoutExercise> updatedExercises = [..._currentWorkout!.exercises];
    updatedExercises[_currentWorkout!.exercises.length - 1] = currentExercise
        .copyWith(endTime: DateTime.now());

    _currentWorkout = _currentWorkout!.copyWith(exercises: updatedExercises);

    unawaited(_saveCurrentWorkout());
    _logger.info('Finished exercise ${currentExercise.name}');
  }

  Future<void> finishWorkout(
    int? reps,
    double? weight,
    Duration? duration,
  ) async {
    if (_currentWorkout == null) {
      _logger.error('No current workout to finish');
      return;
    }
    if (reps != null && weight != null && duration != null) {
      await finishCurrentExercise(reps, weight, duration);
    }

    _currentWorkout = _currentWorkout!.copyWith(
      endTime: DateTime.now(),
      isOngoing: false,
    );

    unawaited(_saveWorkoutToHistory());
    unawaited(_clearCurrentWorkout());

    // Try to upload to backend
    unawaited(_uploadWorkout(_currentWorkout!));

    _logger.info('Workout finished and saved');
    _currentWorkout = null;
  }

  Future<List<Workout>> getWorkoutHistory() async {
    return _historyStorage.getAll();
  }

  Future<void> loadCurrentWorkout() async {
    try {
      _currentWorkout = await _currentWorkoutStorage.load();
      if (_currentWorkout != null) {
        _logger.info('Loaded current workout with ID: ${_currentWorkout!.id}');
      }
    } catch (e, st) {
      _logger.warning('Failed to load current workout', e, st);
      await _clearCurrentWorkout();
    }
  }

  Future<void> loadWorkoutToFollow() async {
    try {
      _workoutToFollow = await _currentWorkoutStorage.loadWorkoutToFollow();
      if (_workoutToFollow != null) {
        _logger.info('Loaded workoutToFollow with ID: ${_workoutToFollow!.id}');
      }
    } catch (e, st) {
      _logger.warning('Failed to load workoutToFollow', e, st);
      _workoutToFollow = null;
    }
  }

  Future<void> uploadPendingWorkouts() async {
    final workouts = await getWorkoutHistory();
    final pendingWorkouts = workouts.where((w) => !w.isUploaded).toList();

    for (final workout in pendingWorkouts) {
      unawaited(_uploadWorkout(workout));
    }
  }

  Future<void> _saveCurrentWorkout() async {
    if (_currentWorkout == null) {
      return _currentWorkoutStorage.clear();
    }
    try {
      await _currentWorkoutStorage.save(_currentWorkout!);
    } catch (e, st) {
      _logger.warning('Failed to persist current workout', e, st);
    }
  }

  Future<void> _saveWorkoutToFollow() async {
    if (_workoutToFollow == null) {
  await _currentWorkoutStorage.deleteWorkoutToFollowOnly();
      return;
    }
    try {
      await _currentWorkoutStorage.saveWorkoutToFollow(_workoutToFollow!);
    } catch (e, st) {
      _logger.warning('Failed to persist workoutToFollow', e, st);
    }
  }

  Future<void> _saveWorkoutToHistory() async {
    if (_currentWorkout == null) return;
    try {
      await _historyStorage.add(_currentWorkout!);
    } catch (e, st) {
      _logger.warning('Failed to save workout to history', e, st);
    }
  }

  Future<void> _clearCurrentWorkout() async {
    try {
      await _currentWorkoutStorage.clear();
    } catch (e, st) {
      _logger.warning('Failed to clear current workout', e, st);
    }
  }

  Future<void> _uploadWorkout(Workout workout) async {
    try {
      // Convert all times to UTC+0
      final startTimeUtc = workout.startTime.toUtc();
      final endTimeUtc = (workout.endTime ?? DateTime.now()).toUtc();

      _logger.info("StartTime:");
      _logger.info(startTimeUtc.toString());
      _logger.info("EndTime:");
      _logger.info(endTimeUtc.toString());

      // Build DTO request from domain model
      final request = WorkoutCreateRequest(
        id: workout.id,
        name: workout.name,
        exercises:
            workout.exercises
                .map(
                  (e) => WorkoutExerciseDto(
                    exerciseId: e.exerciseId,
                    name: e.name,
                    muscleGroup: e.muscleGroup,
                    sets:
                        e.sets
                            .map(
                              (s) => WorkoutSetDto(
                                setNumber: s.setNumber,
                                reps: s.reps,
                                weight: s.weight,
                                time: s.time.inSeconds,
                              ),
                            )
                            .toList(),
                    startTime: e.startTime.toUtc(),
                    endTime: e.endTime?.toUtc(),
                  ),
                )
                .toList(),
        startTime: startTimeUtc,
        endTime: endTimeUtc,
      );

      final response = await _workoutApiService.createWorkout(request);
      _logger.info(response.success.toString());

      if (response.success) {
        // Mark as uploaded in history
        await _markWorkoutAsUploaded(workout.id);
        _logger.info('Successfully uploaded workout ${workout.id}');
      } else {
        _logger.warning(
          'Workout upload failed ${workout.id}: status=${response.status}, error=${response.error}, message=${response.message}',
        );
      }
    } catch (e, st) {
      _logger.warning('Failed to upload workout ${workout.id}', e, st);
    }
  }

  Future<void> _markWorkoutAsUploaded(String workoutId) async {
    await _historyStorage.markUploaded(workoutId);
  }

  int getExerciseIdx() {
    if (_currentWorkout == null || _currentWorkout!.exercises.isEmpty) {
      return 0;
    }
    if (_workoutToFollow == null) {
      return _currentWorkout!.exercises.length - 1;
    }
    //todo if exercise has been finished, then return _currentWorkout!.exercises.length;
    final totalAmountOfSetsForExercise =
        _workoutToFollow!
            .exercises[_currentWorkout!.exercises.length - 1]
            .setsAmount;

    final setsPerformedForExercise =
        _currentWorkout!.exercises.last.sets.length;
    if (totalAmountOfSetsForExercise == setsPerformedForExercise) {
      return _currentWorkout!.exercises.length;
    }
    return _currentWorkout!.exercises.length - 1;
  }

  int getSetIdx() {
    if (_currentWorkout == null || // Current Workout does not exist
        _currentWorkout!
            .exercises
            .isEmpty || // Current workout does not have any exercises
        _currentWorkout!.exercises.length ==
            getExerciseIdx() // the amount of performed exercises in current workout equals to the current workout idx
            ) {
      return 0;
    }
    return _currentWorkout!.exercises[getExerciseIdx()].sets.length;
  }

  double? getPercentageDone() {
    if (_currentWorkout == null || _workoutToFollow == null) {
      return null;
    }

    final totalSets = _workoutToFollow!.exercises.fold<int>(
      0,
      (sum, e) => sum + e.setsAmount,
    );
    final completedSets = _currentWorkout!.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.length,
    );

    return totalSets > 0 ? completedSets / totalSets : 0.0;
  }

  void reorderUpcomingExercises(int startIndex, List<String> newOrderIds) {
    if (_workoutToFollow == null) return;
    // Defensive bounds
    if (startIndex < 0 || startIndex >= _workoutToFollow!.exercises.length) {
      return;
    }
    final before = _workoutToFollow!.exercises.take(startIndex).toList();
    final reorderSlice = _workoutToFollow!.exercises.skip(startIndex).toList();
    // Build map for quick lookup
    final map = {
      for (final e in reorderSlice) e.id: e,
    };
    final reordered = <CustomWorkoutExercise>[];
    for (final id in newOrderIds) {
      final ex = map[id];
      if (ex != null) reordered.add(ex);
    }
    // Append any missing exercises (shouldn't normally happen)
    for (final ex in reorderSlice) {
      if (!reordered.contains(ex)) reordered.add(ex);
    }
    _workoutToFollow = _workoutToFollow!.copyWith(
      exercises: [...before, ...reordered],
    );
  }
}
