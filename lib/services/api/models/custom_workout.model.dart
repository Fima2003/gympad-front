class CustomWorkoutR {
  final String customWorkoutId;
  final String name;
  final String description;
  final List<CustomWorkoutExerciseR> exercises;
  final String difficulty;
  final List<String> muscleGroups;
  final int estimatedCalories;

  CustomWorkoutR({
    required this.customWorkoutId,
    required this.name,
    required this.description,
    required this.exercises,
    required this.difficulty,
    required this.muscleGroups,
    required this.estimatedCalories,
  });

  factory CustomWorkoutR.fromJson(Map<String, dynamic> json) {
    var exercisesFromJson = json['exercises'] as List;
    List<CustomWorkoutExerciseR> exerciseList = exercisesFromJson
        .map((exercise) => CustomWorkoutExerciseR.fromJson(exercise))
        .toList();

    return CustomWorkoutR(
      customWorkoutId: json['customWorkoutId'],
      name: json['name'],
      description: json['description'],
      exercises: exerciseList,
      difficulty: json['difficulty'],
      muscleGroups: List<String>.from(json['muscleGroups']),
      estimatedCalories: json['estimatedCalories'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'customWorkoutId': customWorkoutId,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'muscleGroups': muscleGroups,
      'estimatedCalories': estimatedCalories,
    };

    json['exercises'] = exercises.map((e) => e.toJson()).toList();
    return json;
  }
}

class CustomWorkoutExerciseR {
  final String exerciseId;
  final String name;
  final int setsAmount;
  final double suggestedWeight;
  final int suggestedReps;
  final int restTime;

  CustomWorkoutExerciseR({
    required this.exerciseId,
    required this.name,
    required this.setsAmount,
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.restTime,
  });

  factory CustomWorkoutExerciseR.fromJson(Map<String, dynamic> json) {
    return CustomWorkoutExerciseR(
      exerciseId: json['exerciseId'],
      name: json['name'],
      setsAmount: json['setsAmount'],
      suggestedWeight: (json['suggestedWeight'] as num).toDouble(),
      suggestedReps: json['suggestedReps'],
      restTime: json['restTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'setsAmount': setsAmount,
      'suggestedWeight': suggestedWeight,
      'suggestedReps': suggestedReps,
      'restTime': restTime,
    };  
  }
}