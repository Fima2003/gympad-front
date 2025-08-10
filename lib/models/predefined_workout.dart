class PredefinedWorkout {
  final String id;
  final String name;
  final String description;
  final String difficulty;
  final List<String> muscleGroups;
  final String? imageUrl;
  final List<PredefinedWorkoutExercise> exercises;
  final int? estimatedCalories;

  PredefinedWorkout({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.muscleGroups,
    this.imageUrl,
    required this.exercises,
    this.estimatedCalories,
  });

  factory PredefinedWorkout.fromJson(String id, Map<String, dynamic> json) {
    List<PredefinedWorkoutExercise> exercisesList = [];
    json.forEach((key, value) {
      if (key != 'name' && key != 'description' && key != 'difficulty' && 
          key != 'muscle_groups' && key != 'image_url' && key != 'estimated_calories') {
        try {
          exercisesList.add(PredefinedWorkoutExercise.fromJson(key, value));
        } catch (e) {
          // Skip invalid exercises but continue parsing
        }
      }
    });

    return PredefinedWorkout(
      id: id,
      name: json['name'] ?? id.replaceAll('_', ' '),
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'Beginner',
      muscleGroups: (json['muscle_groups'] as List<dynamic>?)?.cast<String>() ?? [],
      imageUrl: json['image_url'],
      exercises: exercisesList,
      estimatedCalories: json['estimated_calories'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'muscle_groups': muscleGroups,
      'image_url': imageUrl,
      'estimated_calories': estimatedCalories,
    };

    for (var exercise in exercises) {
      json[exercise.name] = exercise.toJson();
    }

    return json;
  }
}

class PredefinedWorkoutExercise {
  final String name;
  final int setsAmount;
  final double? suggestedWeight;
  final int restTime; // in seconds
  final int? suggestedReps;

  PredefinedWorkoutExercise({
    required this.name,
    required this.setsAmount,
    this.suggestedWeight,
    required this.restTime,
    this.suggestedReps,
  });

  factory PredefinedWorkoutExercise.fromJson(String name, Map<String, dynamic> json) {
    return PredefinedWorkoutExercise(
      name: name,
      setsAmount: json['sets_amount'] ?? 3,
      suggestedWeight: json['weight']?.toDouble(),
      restTime: json['rest_time'] ?? 90,
      suggestedReps: json['suggested_reps'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sets_amount': setsAmount,
      'weight': suggestedWeight,
      'rest_time': restTime,
      'suggested_reps': suggestedReps,
    };
  }
}
