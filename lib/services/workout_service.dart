import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../services/api/api.dart';
import '../services/logger_service.dart';

enum WorkoutType { custom, free, personal }

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  static const String _currentWorkoutKey = 'current_workout';
  static const String _workoutHistoryKey = 'workout_history';

  final AppLogger _logger = AppLogger();
  final WorkoutApiService _workoutApiService = WorkoutApiService();

  Workout? _currentWorkout;
  Workout? get currentWorkout => _currentWorkout;

  Future<void> startWorkout(WorkoutType type, {String? name}) async {
    if (_currentWorkout != null && _currentWorkout!.isOngoing) {
      _logger.warning('Workout already in progress');
      return;
    }

    _currentWorkout = Workout(
      id:
          "${type == WorkoutType.free ? 'free' : 'custom'}_${DateTime.now().millisecondsSinceEpoch.toString()}",
      name: name,
      exercises: [],
      startTime: DateTime.now(),
    );

    await _saveCurrentWorkout();
    _logger.info('New workout started with ID: ${_currentWorkout!.id}');
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
      await _saveCurrentWorkout();
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

    final updatedExercises = [..._currentWorkout!.exercises];
    updatedExercises[currentExerciseIndex] = updatedExercise;

    _currentWorkout = _currentWorkout!.copyWith(exercises: updatedExercises);

    await _saveCurrentWorkout();
    _logger.info('Added set to exercise ${currentExercise.name}');
  }

  Future<void> finishCurrentExercise() async {
    if (_currentWorkout == null || _currentWorkout!.exercises.isEmpty) {
      _logger.error('No current exercise to finish');
      return;
    }

    final currentExerciseIndex = _currentWorkout!.exercises.length - 1;
    final currentExercise = _currentWorkout!.exercises[currentExerciseIndex];

    if (currentExercise.endTime != null) {
      _logger.warning('Exercise already finished');
      return;
    }

    final updatedExercise = currentExercise.copyWith(endTime: DateTime.now());
    final updatedExercises = [..._currentWorkout!.exercises];
    updatedExercises[currentExerciseIndex] = updatedExercise;

    _currentWorkout = _currentWorkout!.copyWith(exercises: updatedExercises);

    await _saveCurrentWorkout();
    _logger.info('Finished exercise ${currentExercise.name}');
  }

  Future<void> finishWorkout() async {
    if (_currentWorkout == null) {
      _logger.error('No current workout to finish');
      return;
    }

    // Finish the last exercise if it hasn't been finished yet
    if (_currentWorkout!.exercises.isNotEmpty) {
      await finishCurrentExercise();
    }

    _currentWorkout = _currentWorkout!.copyWith(
      endTime: DateTime.now(),
      isOngoing: false,
    );

    await _saveWorkoutToHistory();
    await _clearCurrentWorkout();

    // Try to upload to backend
    unawaited(_uploadWorkout(_currentWorkout!));

    _logger.info('Workout finished and saved');
    _currentWorkout = null;
  }

  Future<List<Workout>> getWorkoutHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_workoutHistoryKey);

    if (historyJson == null) return [];

    final historyList = json.decode(historyJson) as List;
    return historyList.map((json) => Workout.fromJson(json)).toList();
  }

  Future<void> loadCurrentWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutJson = prefs.getString(_currentWorkoutKey);

    if (workoutJson != null) {
      try {
        _currentWorkout = Workout.fromJson(json.decode(workoutJson));
        _logger.info('Loaded current workout with ID: ${_currentWorkout!.id}');
      } catch (e, st) {
        _logger.error('Failed to load current workout', e, st);
        await _clearCurrentWorkout();
      }
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
    if (_currentWorkout == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _currentWorkoutKey,
      json.encode(_currentWorkout!.toJson()),
    );
  }

  Future<void> _saveWorkoutToHistory() async {
    if (_currentWorkout == null) return;

    final workouts = await getWorkoutHistory();
    workouts.add(_currentWorkout!);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _workoutHistoryKey,
      json.encode(workouts.map((w) => w.toJson()).toList()),
    );
  }

  Future<void> _clearCurrentWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentWorkoutKey);
  }

  Future<void> _uploadWorkout(Workout workout) async {
    try {
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
                    equipmentId: e.equipmentId,
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
                    startTime: e.startTime,
                    endTime: e.endTime,
                  ),
                )
                .toList(),
        startTime: workout.startTime,
        endTime: workout.endTime ?? DateTime.now(),
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
    final workouts = await getWorkoutHistory();
    final index = workouts.indexWhere((w) => w.id == workoutId);

    if (index != -1) {
      workouts[index] = workouts[index].copyWith(isUploaded: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _workoutHistoryKey,
        json.encode(workouts.map((w) => w.toJson()).toList()),
      );
    }
  }
}
