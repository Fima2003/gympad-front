import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_set.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _workoutDataKey = 'workout_data';

  Future<void> saveWorkoutSets(String exerciseId, List<WorkoutSet> sets) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing data
    final existingData = await getAllWorkoutData();
    
    // Add new workout session
    existingData[exerciseId] = sets.map((set) => set.toJson()).toList();
    
    // Save back to preferences
    await prefs.setString(_workoutDataKey, json.encode(existingData));
  }

  Future<List<WorkoutSet>> getWorkoutSets(String exerciseId) async {
    final allData = await getAllWorkoutData();
    final setsData = allData[exerciseId] as List<dynamic>?;
    
    if (setsData == null) return [];
    
    return setsData
        .map((setData) => WorkoutSet.fromJson(setData as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getAllWorkoutData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_workoutDataKey);
    
    if (dataString == null) return {};
    
    return json.decode(dataString) as Map<String, dynamic>;
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workoutDataKey);
  }
}
