import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import '../models/custom_workout.dart';
import '../models/withAdapters/exercise.dart';
import '../models/equipment.dart';
import 'api/custom_workout_api_service.dart';
import 'api/exercise_api_service.dart';
import 'hive/custom_workout_lss.dart';
import 'hive/exercise_lss.dart';
import 'hive/user_auth_lss.dart';
import 'logger_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
  final _logger = AppLogger().createLogger('DataService');

  Map<String, Exercise>? _exercises;
  Map<String, Equipment>? _equipment;
  Map<String, CustomWorkout>? _customWorkouts;
  final CustomWorkoutApiService _customWorkoutApiService =
      CustomWorkoutApiService();
  final CustomWorkoutLss _customWorkoutLssService = CustomWorkoutLss();
  final ExerciseApiService _exerciseApiService = ExerciseApiService();
  final ExerciseLss _exerciseLssService = ExerciseLss();
  final UserAuthLocalStorageService _userAuthStorage =
      UserAuthLocalStorageService();

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
          for (var exercise in localExercises) exercise.exerciseId: exercise,
        };
        _logger.log(
          Level.INFO,
          "Loaded ${_exercises?.length ?? 0} exercises from local storage",
        );
      } else {
        _exercises = {};
        _logger.log(Level.WARNING, "No local exercises available");
      }
      return;
    }

    final exercises = response.data!.map((e) => e.toDomain()).toList();
    _exerciseLssService.saveMany(exercises);

    _exercises = {};
    for (final exercise in exercises) {
      _exercises![exercise.exerciseId] = exercise;
    }
    _logger.log(
      Level.INFO,
      "Received ${_exercises?.length ?? 0} exercise from API",
    );
  }

  Future<void> _loadCustomWorkouts() async {
    final level = _userAuthStorage.get().then((user) => user?.level);
    String userLevel = (await level)?.name ?? "Beginner";
    userLevel =
        userLevel[0].toUpperCase() + userLevel.substring(1).toLowerCase();
    final response = await _customWorkoutApiService.getCustomWorkouts(
      userLevel,
    );
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
    _logger.info("Received ${_customWorkouts?.length ?? 0} workouts from API");
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
}
