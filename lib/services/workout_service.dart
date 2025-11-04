import 'dart:async';

import 'package:gympad/models/personal_workout.dart';
import 'package:gympad/services/hive/personal_workout_lss.dart';

import '../models/custom_workout.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/api/api.dart';
import '../services/logger_service.dart';
import '../models/capabilities.dart';
import 'api/models/personal_workout.model.dart';
import 'hive/current_workout_lss.dart';
import 'hive/workout_history_lss.dart';
import 'hive/workout_to_follow_lss.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  final AppLogger _logger = AppLogger();
  final PersonalWorkoutLocalService _personalLocal =
      PersonalWorkoutLocalService();
  CapabilitiesProvider _capabilitiesProvider = () => Capabilities.guest;

  void configureCapabilitiesProvider(CapabilitiesProvider provider) {
    _capabilitiesProvider = provider;
  }

  final WorkoutApiService _workoutApiService = WorkoutApiService();

  Workout? _currentWorkout;
  Workout? get currentWorkout => _currentWorkout;

  CustomWorkout? _workoutToFollow;
  CustomWorkout? get workoutToFollow => _workoutToFollow;

  final _currentWorkoutStorage = CurrentWorkoutLocalStorageService();
  final _workoutToFollowStorage = WorkoutToFollowLss();
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

    String idType;
    switch (type) {
      case (WorkoutType.custom):
        idType = 'custom';
        break;
      case (WorkoutType.free):
        idType = 'free';
        break;
      default:
        idType = 'personal';
    }

    _currentWorkout = Workout(
      id: "${idType}_${DateTime.now().millisecondsSinceEpoch.toString()}",
      name: workoutToFollow?.name,
      workoutType: workoutToFollow?.workoutType ?? type,
      exercises: [],
      startTime: DateTime.now(),
      createdWhileGuest: !_capabilitiesProvider().canUpload,
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

  Future<Workout?> finishWorkout(
    int? reps,
    double? weight,
    Duration? duration,
  ) async {
    if (_currentWorkout == null) {
      _logger.error('No current workout to finish');
      return null;
    }
    if (reps != null && weight != null && duration != null) {
      await finishCurrentExercise(reps, weight, duration);
    }

    _currentWorkout = _currentWorkout!.copyWith(
      endTime: DateTime.now(),
      isOngoing: false,
    );
    final finished = _currentWorkout; // snapshot before nulling

    unawaited(_saveWorkoutToHistory());
    unawaited(_clearCurrentWorkout());

    // Try to upload to backend (fire and forget)
    if (finished != null) {
      unawaited(
        _uploadWorkout(finished, workoutToFollowId: _workoutToFollow?.id),
      );
    }
    unawaited(_clearWorkoutToFollow());

    _logger.info('Workout finished and saved');
    _currentWorkout = null;
    return finished;
  }

  Future<List<Workout>> getWorkoutHistory() async {
    return _historyStorage.getAll();
  }

  Future<void> loadCurrentWorkout() async {
    try {
      _currentWorkout = await _currentWorkoutStorage.get();
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
      _workoutToFollow = await _workoutToFollowStorage.get();
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
      unawaited(_uploadWorkout(workout, updateExercises: false));
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
      await _workoutToFollowStorage.delete();
      return;
    }
    try {
      await _workoutToFollowStorage.save(_workoutToFollow!);
    } catch (e, st) {
      _logger.warning('Failed to persist workoutToFollow', e, st);
    }
  }

  Future<void> _saveWorkoutToHistory() async {
    if (_currentWorkout == null) return;
    try {
      await _historyStorage.save(_currentWorkout!);
    } catch (e, st) {
      _logger.warning('Failed to save workout to history', e, st);
    }
  }

  Future<void> _clearCurrentWorkout() async {
    try {
      _currentWorkout = null;
      await _currentWorkoutStorage.clear();
    } catch (e, st) {
      _logger.warning('Failed to clear current workout', e, st);
    }
  }

  Future<void> _clearWorkoutToFollow() async {
    try {
      await _workoutToFollowStorage.clear();
      _workoutToFollow = null;
    } catch (e, st) {
      _logger.warning('Failed to clear workoutToFollow', e, st);
    }
  }

  Future<void> _uploadWorkout(
    Workout workout, {
    bool updateExercises = true,
    String? workoutToFollowId,
  }) async {
    try {
      final caps = _capabilitiesProvider();
      if (!caps.canUpload) {
        _logger.info('Skipping workout upload (guest mode): ${workout.id}');
        return; // Do not attempt network call in guest mode
      }
      // Convert all times to UTC+0
      final startTimeUtc = workout.startTime.toUtc();
      final endTimeUtc = (workout.endTime ?? DateTime.now()).toUtc();

      _logger.info("StartTime:");
      _logger.info(startTimeUtc.toString());
      _logger.info("EndTime:");
      _logger.info(endTimeUtc.toString());

      // Build DTO request from domain model
      final request = WorkoutCreateRequest.fromWorkoutAndWorkoutToFollowId(
        workout.copyWith(startTime: startTimeUtc, endTime: endTimeUtc),
        workoutToFollowId,
      );

      final response = await _workoutApiService.logNewWorkout(request);
      if (updateExercises &&
          workout.workoutType == WorkoutType.personal &&
          response.success &&
          response.data != null &&
          response.data!.nextWorkoutExercises != null &&
          workoutToFollowId != null) {
        final exercises = response.data!.nextWorkoutExercises!;
        await _personalLocal.update(
          key: workoutToFollowId,
          copyWithFn: (c) {
            final newExercises = exercises.map((e) => e.toDomain()).toList();
            return c.copyWith(exercises: newExercises);
          },
        );
        // await _personalLocal.updateExercises(
        //   workoutToFollowId,
        //   exercises.map((e) => e.toDomain()).toList(),
        // );
      }
      _logger.info(response.success.toString());

      if (response.success || response.status == 409) {
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
    final map = {for (final e in reorderSlice) e.id: e};
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
    unawaited(_saveWorkoutToFollow());
  }

  Future<List<PersonalWorkout>> getPersonalWorkouts() async {
    final caps = _capabilitiesProvider();
    if (!caps.canSync) {
      _logger.info('Skipping fetching personal workouts (guest mode)');
      final cached = await _personalLocal.getAll();
      return cached;
    }
    final resp = await _workoutApiService.getPersonalWorkouts();
    if (resp.success && resp.data != null) {
      final list = resp.data!;
      await _personalLocal.saveMany(list);
      return list;
    } else {
      final cached = await _personalLocal.getAll();
      return cached;
    }
  }

  Future<bool> savePersonalWorkout(CreatePersonalWorkoutRequest req) async {
    final resp = await WorkoutApiService().createPersonalWorkout(req);
    return resp.success;
  }

  Future<void> clearAll() async {
    await _currentWorkoutStorage.clear();
    await _workoutToFollowStorage.clear();
    await _historyStorage.clear();
    await _personalLocal.clear();
    _currentWorkout = null;
    _workoutToFollow = null;
    _logger.info('Cleared all workout data');
  }
}
