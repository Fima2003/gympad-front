import 'package:hive/hive.dart';
import '../../../models/personal_workout.dart';

part 'hive_personal_workout.g.dart';

@HiveType(typeId: 0)
class HivePersonalWorkoutExercise extends HiveObject {
  @HiveField(0)
  String exerciseId;
  @HiveField(1)
  String name;
  @HiveField(2)
  int sets;
  @HiveField(3)
  double weight;
  @HiveField(4)
  int reps;
  @HiveField(5)
  int restTime;

  HivePersonalWorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.weight,
    required this.reps,
    required this.restTime,
  });

  factory HivePersonalWorkoutExercise.fromDomain(PersonalWorkoutExercise e) =>
      HivePersonalWorkoutExercise(
        exerciseId: e.exerciseId,
        name: e.name,
        sets: e.sets,
        weight: e.weight,
        reps: e.reps,
        restTime: e.restTime,
      );

  PersonalWorkoutExercise toDomain() => PersonalWorkoutExercise(
        exerciseId: exerciseId,
        name: name,
        sets: sets,
        reps: reps,
        weight: weight,
        restTime: restTime,
      );
}

@HiveType(typeId: 1)
class HivePersonalWorkout extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String? description;
  @HiveField(2)
  List<HivePersonalWorkoutExercise> exercises;

  HivePersonalWorkout({
    required this.name,
    required this.description,
    required this.exercises,
  });

  factory HivePersonalWorkout.fromDomain(PersonalWorkout w) => HivePersonalWorkout(
        name: w.name,
        description: w.description,
        exercises: w.exercises
            .map(HivePersonalWorkoutExercise.fromDomain)
            .toList(),
      );

  PersonalWorkout toDomain() => PersonalWorkout(
        name: name,
        description: description,
        exercises: exercises.map((e) => e.toDomain()).toList(),
      );
}
