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

    // estimated_calories in the JSON is inconsistent: sometimes an int, sometimes a
    // list like ["300-350 kcal"]. We normalize to an approximate integer (average
    // of numbers found) or null if unparseable.
    int? parsedCalories;
    final dynamic rawCalories = json['estimated_calories'];
    if (rawCalories is int) {
      parsedCalories = rawCalories;
    } else if (rawCalories is String) {
      final nums =
          RegExp(r'(\d+)')
              .allMatches(rawCalories)
              .map((m) => int.tryParse(m.group(1)!))
              .whereType<int>()
              .toList();
      if (nums.isNotEmpty) {
        parsedCalories = (nums.reduce((a, b) => a + b) / nums.length).round();
      }
    } else if (rawCalories is List) {
      if (rawCalories.isNotEmpty) {
        final first = rawCalories.first;
        if (first is int) {
          parsedCalories = first;
        } else if (first is String) {
          final nums =
              RegExp(r'(\d+)')
                  .allMatches(first)
                  .map((m) => int.tryParse(m.group(1)!))
                  .whereType<int>()
                  .toList();
          if (nums.isNotEmpty) {
            parsedCalories =
                (nums.reduce((a, b) => a + b) / nums.length).round();
          }
        }
      }
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
      estimatedCalories: parsedCalories,
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
