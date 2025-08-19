import 'package:gympad/models/personal_workout.dart';

class CustomWorkout {
  final String id;
  final String name;
  final String description;
  final String difficulty;
  final List<String> muscleGroups;
  final String? imageUrl;
  final List<CustomWorkoutExercise> exercises;
  final int? estimatedCalories;

  CustomWorkout({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.muscleGroups,
    this.imageUrl,
    required this.exercises,
    this.estimatedCalories,
  });

  factory CustomWorkout.fromPersonalWorkout(PersonalWorkout workout) {
    return CustomWorkout(
      id: workout.name.toLowerCase().replaceAll(' ', '_'),
      name: workout.name,
      description: workout.description ?? "",
      difficulty: 'none',
      muscleGroups: workout.getMuscleGroups(),
      imageUrl: '',
      exercises:
          workout.exercises.map((e) {
            return CustomWorkoutExercise(
              id: e.exerciseId,
              setsAmount: e.sets,
              suggestedWeight: e.weight,
              restTime: e.restTime,
              suggestedReps: e.reps,
            );
          }).toList(),
      estimatedCalories: 0,
    );
  }

  factory CustomWorkout.fromJson(String id, Map<String, dynamic> json) {
    List<CustomWorkoutExercise> exercisesList = [];
    if (json['exercises'] is List) {
      for (final item in (json['exercises'] as List)) {
        if (item is Map<String, dynamic>) {
          try {
            exercisesList.add(CustomWorkoutExercise.fromMap(item));
          } catch (_) {
            // Skip invalid exercises but continue parsing
          }
        }
      }
    } else {
      // Backward compatibility: collect any unknown keys as exercises
      json.forEach((key, value) {
        if (key != 'name' &&
            key != 'description' &&
            key != 'difficulty' &&
            key != 'muscle_groups' &&
            key != 'image_url' &&
            key != 'estimated_calories') {
          try {
            exercisesList.add(CustomWorkoutExercise.fromLegacy(key, value));
          } catch (_) {}
        }
      });
    }

    return CustomWorkout(
      id: id,
      name: json['name'] ?? id.replaceAll('_', ' '),
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'Beginner',
      muscleGroups:
          (json['muscle_groups'] as List<dynamic>?)?.cast<String>() ?? [],
      imageUrl: json['image_url'],
      exercises: exercisesList,
      estimatedCalories: json['estimated_calories'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'muscle_groups': muscleGroups,
      'image_url': imageUrl,
      'estimated_calories': estimatedCalories,
    };

    json['exercises'] = exercises.map((e) => e.toJson()).toList();
    return json;
  }
}

class CustomWorkoutExercise {
  final String id;
  final int setsAmount;
  final double? suggestedWeight;
  final int restTime; // in seconds
  final int? suggestedReps;

  CustomWorkoutExercise({
    required this.id,
    required this.setsAmount,
    this.suggestedWeight,
    required this.restTime,
    this.suggestedReps,
  });

  factory CustomWorkoutExercise.fromMap(Map<String, dynamic> json) {
    return CustomWorkoutExercise(
      id: json['id'] as String,
      setsAmount: json['sets_amount'] ?? 3,
      suggestedWeight:
          json['weight'] == null ? null : (json['weight'] as num).toDouble(),
      restTime: json['rest_time'] ?? 90,
      suggestedReps: json['suggested_reps'],
    );
  }

  // Legacy support when workout JSON used top-level exercise keys
  factory CustomWorkoutExercise.fromLegacy(
    String id,
    Map<String, dynamic> json,
  ) {
    return CustomWorkoutExercise(
      id: id,
      setsAmount: json['sets_amount'] ?? 3,
      suggestedWeight:
          json['weight'] == null ? null : (json['weight'] as num).toDouble(),
      restTime: json['rest_time'] ?? 90,
      suggestedReps: json['suggested_reps'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sets_amount': setsAmount,
      'weight': suggestedWeight,
      'rest_time': restTime,
      'suggested_reps': suggestedReps,
    };
  }
}
