import 'dart:async';
import 'package:logging/logging.dart';
import '../models/custom_workout.dart';
import '../models/withAdapters/exercise.dart';
import '../models/equipment.dart';
import 'api/api.dart';
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
      await _loadExercises(
        await _userAuthStorage.get().then((user) => user?.goal) ??
            "generalFitness",
      );
    }
    if (_customWorkouts == null) {
      await _loadCustomWorkouts();
    }
  }

  Future<void> _loadExercises(String goal) async {
    final response = await _exerciseApiService.getExercises(goal);

    return response.fold(
      onError: (error) {
        _logger.log(Level.WARNING, "Failed to fetch exercises: $error");
        return _exerciseLssService.getAll().then((localExercises) {
          if (localExercises.isNotEmpty) {
            _exercises = {
              for (var exercise in localExercises)
                exercise.exerciseId: exercise,
            };
            _logger.log(
              Level.INFO,
              "Loaded ${_exercises?.length ?? 0} exercises from local storage",
            );
          } else {
            _exercises = {};
            _logger.log(Level.WARNING, "No local exercises available");
          }
        });
      },
      onSuccess: (data) {
        _exerciseLssService.saveMany(data);

        _exercises = {};
        for (final exercise in data) {
          _exercises![exercise.exerciseId] = exercise;
        }
        _logger.log(
          Level.INFO,
          "Received ${_exercises?.length ?? 0} exercise from API",
        );
      },
    );
  }

  Future<void> _loadCustomWorkouts() async {
    final level = await _userAuthStorage.get().then((user) => user?.level);
    String userLevel = level?.name ?? "Beginner";
    userLevel =
        userLevel[0].toUpperCase() + userLevel.substring(1).toLowerCase();
    final response = await _customWorkoutApiService.getCustomWorkoutsByField(
      userLevel,
    );
    response.fold(
      onError: (error) async {
        _logger.log(Level.WARNING, "Failed to fetch custom workouts: $error");
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
      },
      onSuccess: (data) {
        final customWorkouts = data.map((e) => e.toDomain()).toList();

        _customWorkouts = {};
        for (final workout in customWorkouts) {
          _customWorkouts![workout.id] = workout;
        }
        _logger.info(
          "Received ${_customWorkouts?.length ?? 0} workouts from API",
        );

        _customWorkoutLssService.saveMany(customWorkouts);
      },
    );
  }
}
