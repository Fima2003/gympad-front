import '../../../models/withAdapters/exercise.dart';

class ExerciseR extends Exercise {
  ExerciseR({
    required super.exerciseId,
    required super.name,
    super.description,
    required super.type,
    super.equipmentId,
    required super.muscleGroup,
    required super.restTime,
    required super.minReps,
    required super.maxReps,
  });

  factory ExerciseR.fromJson(Map<String, dynamic> json) {
    return ExerciseR(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      equipmentId: json['equipmentId'] as String?,
      muscleGroup:
          (json['muscleGroup'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      restTime: json['restTime'] as int,
      minReps: json['minReps'] as int,
      maxReps: json['maxReps'] as int,
    );
  }

  Exercise toDomain() => Exercise(
    exerciseId: exerciseId,
    name: name,
    description: description,
    type: type,
    equipmentId: equipmentId,
    muscleGroup: muscleGroup,
    restTime: restTime,
    minReps: minReps,
    maxReps: maxReps,
  );
}
