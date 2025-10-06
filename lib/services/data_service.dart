import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import '../models/custom_workout.dart';
import '../models/gym.dart';
import '../models/exercise.dart';
import '../models/equipment.dart';
import 'api/custom_workout_api_service.dart';
import 'api/exercise_api_service.dart';
import 'hive/custom_workout_lss.dart';
import 'hive/exercise_lss.dart';
import 'logger_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
  final _logger = AppLogger().createLogger('DataService');

  Map<String, Gym>? _gyms;
  Map<String, Exercise>? _exercises;
  Map<String, Equipment>? _equipment;
  Map<String, CustomWorkout>? _customWorkouts;
  final CustomWorkoutApiService _customWorkoutApiService =
      CustomWorkoutApiService();
  final CustomWorkoutLss _customWorkoutLssService = CustomWorkoutLss();
  final ExerciseApiService _exerciseApiService = ExerciseApiService();
  final ExerciseLss _exerciseLssService = ExerciseLss();

  // Read-only access for BLoC
  Map<String, Exercise> get exercisesMap => _exercises ?? const {};
  Map<String, Equipment> get equipmentMap => _equipment ?? const {};
  Map<String, CustomWorkout> get customWorkoutsMap =>
      _customWorkouts ?? const {};

  Future<void> forceReload() async {
    _exercises = null;
    _equipment = null;
    _customWorkouts = null;
    await loadData();
  }

  Future<void> loadData() async {
    if (_exercises == null) {
      await _loadExercises();
    }
    if (_customWorkouts == null) {
      await _loadCustomWorkouts();
    }
    if (_equipment == null) {
      unawaited(_loadEquipment());
    }
  }

  Future<void> _loadExercises() async {
    final response = await _exerciseApiService.getExercises();
    if (response.error != null) {
      _logger.log(
        Level.WARNING,
        "Failed to fetch exercises: ${response.error}",
      );
      final localExercises = await _exerciseLssService.getAll();
      if (localExercises.isNotEmpty) {
        _exercises = {
          for (var exercise in localExercises) exercise.id: exercise,
        };
        _logger.log(
          Level.INFO,
          "Loaded ${_customWorkouts?.length ?? 0} exercises from local storage",
        );
      } else {
        _customWorkouts = {};
        _logger.log(Level.WARNING, "No local exercise available");
      }
      return;
    }

    final exercises = response.data!.map((e) => e.toDomain()).toList();

    _exercises = {};
    for (final exercise in exercises) {
      _exercises![exercise.id] = exercise;
    }
    AppLogger()
        .createLogger('data_s')
        .log(
          Level.INFO,
          "Received ${_customWorkouts?.length ?? 0} exercise from API",
        );
  }

  Future<void> _loadEquipment() async {
    final String jsonString = await rootBundle.loadString(
      'assets/mock_data/equipment.json',
    );
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    _equipment = {};
    jsonData['equipment'].forEach((key, value) {
      _equipment![key] = Equipment.fromJson(key, value);
    });
  }

  Future<void> _loadCustomWorkouts() async {
    final response = await _customWorkoutApiService.getCustomWorkouts();
    if (response.error != null) {
      _logger.log(
        Level.WARNING,
        "Failed to fetch custom workouts: ${response.error}",
      );
      final localCustomWorkouts = await _customWorkoutLssService.getAll();
      if (localCustomWorkouts.isNotEmpty) {
        _customWorkouts = {
          for (var workout in localCustomWorkouts) workout.id: workout,
        };
        _logger.log(
          Level.INFO,
          "Loaded ${_customWorkouts?.length ?? 0} workouts from local storage",
        );
      } else {
        _customWorkouts = {};
        _logger.log(Level.WARNING, "No local custom workouts available");
      }
      return;
    }

    final customWorkouts = response.data!.map((e) => e.toDomain()).toList();

    _customWorkouts = {};
    for (final workout in customWorkouts) {
      _customWorkouts![workout.id] = workout;
    }
    AppLogger()
        .createLogger('data_s')
        .log(
          Level.INFO,
          "Received ${_customWorkouts?.length ?? 0} workouts from API",
        );
  }

  Gym? getGym(String gymId) {
    return _gyms?[gymId];
  }

  Exercise? getExercise(String exerciseId) {
    return _exercises?[exerciseId];
  }

  Equipment? getEquipment(String equipmentId) {
    return _equipment?[equipmentId];
  }

  String? getExerciseFromEquipment(String equipmentId) {
    final equipment = getEquipment(equipmentId);
    if (equipment == null) return null;

    if (equipment.type == 'direct_exercise') {
      return equipment.data as String;
    }

    // For muscle_group_selector, we'll return the first exercise from the first group
    if (equipment.type == 'muscle_group_selector' && equipment.data is Map) {
      final Map<String, dynamic> data = equipment.data as Map<String, dynamic>;
      for (final group in data.values) {
        if (group is List && group.isNotEmpty) {
          return group[0]['id'] as String;
        }
      }
    }

    return null;
  }

  List<Exercise> getAllExercises() {
    return _exercises?.values.toList() ?? [];
  }

  List<String> getAllMuscleGroups() {
    if (_exercises == null) return [];

    final groups = <String>{};
    for (final exercise in _exercises!.values) {
      groups.add(exercise.muscleGroup);
    }

    return groups.toList()..sort();
  }

  List<Exercise> getExercisesForMuscleGroup(String muscleGroup) {
    if (_exercises == null) return [];

    return _exercises!.values
        .where((exercise) => exercise.muscleGroup == muscleGroup)
        .toList();
  }

  List<String>? getMuscleGroupForExercise(String exerciseId) {
    if (_exercises == null) return null;
    final ex = _exercises![exerciseId];
    if (ex == null) return null;
    return [ex.muscleGroup];
  }
}
