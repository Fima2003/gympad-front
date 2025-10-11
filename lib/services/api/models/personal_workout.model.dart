import '../../../models/personal_workout.dart';

class PersonalWorkoutResponse extends CreatePersonalWorkoutRequest {
  final String workoutId;

  PersonalWorkoutResponse({
    required this.workoutId,
    required super.name,
    super.description,
    required super.exercises,
  });

  factory PersonalWorkoutResponse.fromJson(Map<String, dynamic> json) {
    return PersonalWorkoutResponse(
      workoutId: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      exercises:
          (json['exercises'] as List<dynamic>? ?? const [])
              .map(
                (e) => PersonalWorkoutExerciseDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return CreatePersonalWorkoutRequest(
      name: name,
      description: description,
      exercises: exercises,
    ).toJson();
  }

  PersonalWorkout toDomain() => PersonalWorkout(
    workoutId: workoutId,
    name: name,
    description: description,
    exercises: exercises.map((e) => e.toDomain()).toList(),
  );
}

class CreatePersonalWorkoutRequest {
  final String name;
  final String? description;
  final List<PersonalWorkoutExerciseDto> exercises;

  CreatePersonalWorkoutRequest({
    required this.exercises,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory CreatePersonalWorkoutRequest.fromJson(Map<String, dynamic> json) {
    return CreatePersonalWorkoutRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      exercises:
          (json['exercises'] as List<dynamic>? ?? const [])
              .map(
                (e) => PersonalWorkoutExerciseDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}

class PersonalWorkoutExerciseDto {
  final String exerciseId;
  final String name;
  final int sets;
  final double weight;
  final int reps;
  final int restTime;

  PersonalWorkoutExerciseDto({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restTime,
  });

  PersonalWorkoutExercise toDomain() => PersonalWorkoutExercise(
    exerciseId: exerciseId,
    name: name,
    sets: sets,
    reps: reps,
    weight: weight,
    restTime: restTime,
  );

  factory PersonalWorkoutExerciseDto.fromJson(Map<String, dynamic> json) {
    return PersonalWorkoutExerciseDto(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      restTime: (json['restTime'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'sets': sets,
    'reps': reps,
    'weight': weight,
    'restTime': restTime,
  };
}
