import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/personal_workout.dart';
import 'api/models/workout_models.dart';

/// Local persistence for Personal Workouts using SharedPreferences
class PersonalWorkoutLocalService {
  static final PersonalWorkoutLocalService _instance =
      PersonalWorkoutLocalService._internal();
  factory PersonalWorkoutLocalService() => _instance;
  PersonalWorkoutLocalService._internal();

  static const String _storageKey = 'personal_workouts';

  Future<void> saveAll(List<PersonalWorkoutResponse> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    final list = workouts.map((w) => w.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(list));
  }

  Future<List<PersonalWorkout>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(data) as List<dynamic>;
      return decoded
          .map((e) => PersonalWorkout.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // In case of format issues, reset storage and return empty
      await prefs.remove(_storageKey);
      return [];
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
