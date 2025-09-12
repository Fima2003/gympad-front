import 'package:hive/hive.dart';
import '../../../models/custom_workout.dart';

part 'hive_custom_workout.g.dart';

@HiveType(typeId: 6)
class HiveCustomWorkoutExercise extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  int setsAmount;
  @HiveField(2)
  double? suggestedWeight;
  @HiveField(3)
  int restTime;
  @HiveField(4)
  int? suggestedReps;

  HiveCustomWorkoutExercise({
    required this.id,
    required this.setsAmount,
    required this.suggestedWeight,
    required this.restTime,
    required this.suggestedReps,
  });

  factory HiveCustomWorkoutExercise.fromDomain(CustomWorkoutExercise e) =>
      HiveCustomWorkoutExercise(
        id: e.id,
        setsAmount: e.setsAmount,
        suggestedWeight: e.suggestedWeight,
        restTime: e.restTime,
        suggestedReps: e.suggestedReps,
      );

  CustomWorkoutExercise toDomain() => CustomWorkoutExercise(
    id: id,
    setsAmount: setsAmount,
    suggestedWeight: suggestedWeight,
    restTime: restTime,
    suggestedReps: suggestedReps,
  );
}

@HiveType(typeId: 7)
class HiveCustomWorkout extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String description;
  @HiveField(3)
  String difficulty;
  @HiveField(4)
  List<String> muscleGroups;
  @HiveField(5)
  String? imageUrl;
  @HiveField(6)
  List<HiveCustomWorkoutExercise> exercises;
  @HiveField(7)
  int? estimatedCalories;

  HiveCustomWorkout({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.muscleGroups,
    required this.imageUrl,
    required this.exercises,
    required this.estimatedCalories,
  });

  factory HiveCustomWorkout.fromDomain(CustomWorkout w) => HiveCustomWorkout(
    id: w.id,
    name: w.name,
    description: w.description,
    difficulty: w.difficulty,
    muscleGroups: w.muscleGroups,
    imageUrl: w.imageUrl,
    exercises: w.exercises.map(HiveCustomWorkoutExercise.fromDomain).toList(),
    estimatedCalories: w.estimatedCalories,
  );

  CustomWorkout toDomain() => CustomWorkout(
    id: id,
    name: name,
    description: description,
    difficulty: difficulty,
    muscleGroups: muscleGroups,
    imageUrl: imageUrl,
    exercises: exercises.map((e) => e.toDomain()).toList(),
    estimatedCalories: estimatedCalories,
  );
}
