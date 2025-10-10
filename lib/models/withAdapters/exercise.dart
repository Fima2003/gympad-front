import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 1)
class Exercise extends HiveObject {
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

  Exercise({
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

  factory Exercise.empty() {
    return Exercise(
      exerciseId: '',
      name: '',
      description: '',
      type: '',
      muscleGroup: [],
      restTime: 0,
      minReps: 0,
      maxReps: 0,
    );
  }
}
