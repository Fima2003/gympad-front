import 'package:hive/hive.dart';

import '../../../models/exercise.dart';

part 'hive_exercise.g.dart';

@HiveType(typeId: 1)
class HiveExercise {
  @HiveField(0)
  final String exerciseId;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final String type;
  @HiveField(4)
  final String? equipmentId;
  @HiveField(5)
  final List<String> muscleGroup;
  @HiveField(6)
  final int restTime;
  @HiveField(7)
  final int minReps;
  @HiveField(8)
  final int maxReps;

  HiveExercise({
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

  Exercise toDomain() {
    return Exercise(
      id: exerciseId,
      name: name,
      description: description ?? '',
      image: '',
      muscleGroup: muscleGroup.isNotEmpty ? muscleGroup[0] : 'general',
      equipmentId: equipmentId ?? '',
    );
  }

  factory HiveExercise.fromDomain(Exercise exercise) {
    return HiveExercise(
      exerciseId: exercise.id,
      name: exercise.name,
      description: exercise.description,
      type: 'standard',
      equipmentId:
          exercise.equipmentId.isNotEmpty ? exercise.equipmentId : null,
      muscleGroup: [exercise.muscleGroup],
      restTime: 60,
      minReps: 8,
      maxReps: 12,
    );
  }
}
