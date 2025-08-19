import 'package:gympad/services/api/models/workout_models.dart';
import 'package:gympad/services/data_service.dart';

class PersonalWorkout {
  final String name;
  final String? description;
  final List<PersonalWorkoutExercise> exercises;

  PersonalWorkout({
    required this.name,
    this.description = '',
    required this.exercises,
  });

  List<String> getMuscleGroups() {
    Set<String> muscleGroups = <String>{};

    for (var exercise in exercises) {
      muscleGroups.addAll(exercise.getMuscleGroups());
    }

    return muscleGroups.toList();
  }

  factory PersonalWorkout.fromJson(Map<String, dynamic> json) {
    return PersonalWorkout(
      name: json['name'] as String,
      description: json['description'] as String?,
      exercises:
          (json['exercises'] as List<dynamic>? ?? const [])
              .map(
                (e) =>
                    PersonalWorkoutExercise.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  factory PersonalWorkout.fromResponse(PersonalWorkoutResponse e) {
    return PersonalWorkout(
      name: e.name,
      exercises:
          e.exercises.map((el) => PersonalWorkoutExercise.fromDto(el)).toList(),
      description: e.description,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}

class PersonalWorkoutExercise {
  final _dataService = DataService();
  final String exerciseId;
  final String name;
  final int sets;
  final double weight;
  final int reps;
  final int restTime;

  PersonalWorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restTime,
  });

  List<String> getMuscleGroups() {
    return _dataService.getMuscleGroupForExercise(exerciseId) ?? [];
  }

  factory PersonalWorkoutExercise.fromJson(Map<String, dynamic> json) {
    return PersonalWorkoutExercise(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      restTime: (json['restTime'] as num).toInt(),
    );
  }

  factory PersonalWorkoutExercise.fromDto(PersonalWorkoutExerciseDto dto) {
    return PersonalWorkoutExercise(
      exerciseId: dto.exerciseId,
      name: dto.name,
      sets: dto.sets,
      reps: dto.reps,
      weight: dto.weight,
      restTime: dto.restTime,
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
