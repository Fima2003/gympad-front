import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/gym.dart';
import '../models/exercise.dart';
import '../models/equipment.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  Map<String, Gym>? _gyms;
  Map<String, Exercise>? _exercises;
  Map<String, Equipment>? _equipment;

  Future<void> loadData() async {
    if (_gyms == null) {
      await _loadGyms();
    }
    if (_exercises == null) {
      await _loadExercises();
    }
    if (_equipment == null) {
      await _loadEquipment();
    }
  }

  Future<void> _loadGyms() async {
    final String jsonString = await rootBundle.loadString('assets/mock_data/gyms.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    
    _gyms = {};
    jsonData['gyms'].forEach((key, value) {
      _gyms![key] = Gym.fromJson(key, value);
    });
  }

  Future<void> _loadExercises() async {
    final String jsonString = await rootBundle.loadString('assets/mock_data/exercises.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    
    _exercises = {};
    jsonData['exercises'].forEach((key, value) {
      _exercises![key] = Exercise.fromJson(key, value);
    });
  }

  Future<void> _loadEquipment() async {
    final String jsonString = await rootBundle.loadString('assets/mock_data/equipment.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    
    _equipment = {};
    jsonData['equipment'].forEach((key, value) {
      _equipment![key] = Equipment.fromJson(key, value);
    });
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
}
