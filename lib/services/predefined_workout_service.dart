import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/predefined_workout.dart';
import 'logger_service.dart';

class PredefinedWorkoutService {
  static final PredefinedWorkoutService _instance = PredefinedWorkoutService._internal();
  factory PredefinedWorkoutService() => _instance;
  PredefinedWorkoutService._internal();

  final AppLogger _logger = AppLogger();
  List<PredefinedWorkout>? _cachedWorkouts;

  Future<List<PredefinedWorkout>> loadPredefinedWorkouts() async {
    if (_cachedWorkouts != null) {
      return _cachedWorkouts!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/mock_data/workouts.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      final List<PredefinedWorkout> workouts = [];
      
      jsonMap.forEach((key, value) {
        try {
          workouts.add(PredefinedWorkout.fromJson(key, value));
        } catch (e, stackTrace) {
          _logger.error('Error parsing workout $key', e, stackTrace);
        }
      });

      _cachedWorkouts = workouts;
      _logger.info('Loaded ${workouts.length} predefined workouts');
      return workouts;
    } catch (e, stackTrace) {
      _logger.error('Error loading predefined workouts', e, stackTrace);
      return [];
    }
  }

  PredefinedWorkout? getWorkoutById(String id) {
    return _cachedWorkouts?.firstWhere(
      (workout) => workout.id == id,
      orElse: () => throw StateError('Workout not found'),
    );
  }

  Future<void> refreshWorkouts() async {
    _cachedWorkouts = null;
    await loadPredefinedWorkouts();
  }
}
