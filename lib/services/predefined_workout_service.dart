import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/custom_workout.dart';
import 'logger_service.dart';

class PredefinedWorkoutService {
  static final PredefinedWorkoutService _instance = PredefinedWorkoutService._internal();
  factory PredefinedWorkoutService() => _instance;
  PredefinedWorkoutService._internal();

  final AppLogger _logger = AppLogger();
  List<CustomWorkout>? _cachedWorkouts;

  Future<List<CustomWorkout>> loadPredefinedWorkouts() async {
    if (_cachedWorkouts != null) {
      return _cachedWorkouts!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/mock_data/workouts.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      final List<CustomWorkout> workouts = [];
      
      jsonMap.forEach((key, value) {
        try {
          workouts.add(CustomWorkout.fromJson(key, value));
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

  CustomWorkout? getWorkoutById(String id) {
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
