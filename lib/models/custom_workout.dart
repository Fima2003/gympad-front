enum WorkoutType { custom, free, personal }

class CustomWorkout {
  final String id;
  final String name;
  final WorkoutType workoutType;
  final String description;
  final String difficulty;
  final List<String> muscleGroups;
  final String? imageUrl;
  final List<CustomWorkoutExercise> exercises;
  final int? estimatedCalories;

  CustomWorkout({
    required this.id,
    required this.name,
    required this.workoutType,
    required this.description,
    required this.difficulty,
    required this.muscleGroups,
    this.imageUrl,
    required this.exercises,
    this.estimatedCalories,
  });

  factory CustomWorkout.fromJson(Map<String, dynamic> json, {WorkoutType workoutType = WorkoutType.custom}) {
    List<CustomWorkoutExercise> exercisesList = [];
    if (json['exercises'] is List) {
      for (final item in (json['exercises'] as List)) {
        exercisesList.add(CustomWorkoutExercise.fromMap(item));
      }
    }

    return CustomWorkout(
      id: json["customWorkoutId"] ?? '',
      name: json['name'] ?? '',
      workoutType: json['workoutType'] ?? workoutType,
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'Beginner',
      muscleGroups:
          (json['muscle_groups'] as List<dynamic>?)?.cast<String>() ?? [],
      exercises: exercisesList,
      estimatedCalories: json['estimatedCalories'] ?? 150,
    );
  }

  CustomWorkout copyWith({
    String? id,
    String? name,
    WorkoutType? workoutType,
    String? description,
    String? difficulty,
    List<String>? muscleGroups,
    String? imageUrl,
    List<CustomWorkoutExercise>? exercises,
    int? estimatedCalories,
  }) {
    return CustomWorkout(
      id: id ?? this.id,
      name: name ?? this.name,
      workoutType: workoutType ?? this.workoutType,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      imageUrl: imageUrl ?? this.imageUrl,
      exercises: exercises ?? this.exercises.map((e) => e.copyWith()).toList(),
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
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
  final String name;
  final int setsAmount;
  final double? suggestedWeight;
  final int restTime; // in seconds
  final int? suggestedReps;

  CustomWorkoutExercise({
    required this.id,
    required this.name,
    required this.setsAmount,
    this.suggestedWeight,
    required this.restTime,
    this.suggestedReps,
  });

  factory CustomWorkoutExercise.fromMap(Map<String, dynamic> json) {
    return CustomWorkoutExercise(
      id: json['exerciseId'] as String,
      name: json['name'] as String,
      setsAmount: json['setsAmount'] ?? 3,
      suggestedWeight:
          json['suggestedWeight'] == null
              ? null
              : (json['suggestedWeight'] as num).toDouble(),
      restTime: json['restTime'] ?? 90,
      suggestedReps: json['suggestedReps'],
    );
  }

  CustomWorkoutExercise copyWith({
    String? id,
    String? name,
    int? setsAmount,
    double? suggestedWeight,
    int? restTime,
    int? suggestedReps,
  }) {
    return CustomWorkoutExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      setsAmount: setsAmount ?? this.setsAmount,
      suggestedWeight: suggestedWeight ?? this.suggestedWeight,
      restTime: restTime ?? this.restTime,
      suggestedReps: suggestedReps ?? this.suggestedReps,
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
