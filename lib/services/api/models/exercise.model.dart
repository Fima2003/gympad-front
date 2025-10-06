import '../../../models/exercise.dart';

class ExerciseR {
  final String exerciseId;
  final String name;
  final String? description;
  final String type;
  final String? equipmentId;
  final List<String> muscleGroup;
  final int restTime;
  final int minReps;
  final int maxReps;

  ExerciseR({
    required this.exerciseId,
    required this.name,
    this.description,
    required this.type,
    this.equipmentId,
    required this.muscleGroup,
    required this.restTime,
    required this.minReps,
    required this.maxReps,
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

  Exercise toDomain() {
    return Exercise(
      id: exerciseId,
      name: name,
      description: description ?? '',
      image: '', // Assuming image is not provided in the API response
      muscleGroup: muscleGroup.isNotEmpty ? muscleGroup[0] : 'general',
      equipmentId: equipmentId ?? '',
    );
  }
}
