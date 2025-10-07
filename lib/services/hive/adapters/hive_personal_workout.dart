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

  PersonalWorkoutExercise copyWith({
    String? exerciseId,
    String? name,
    int? sets,
    int? reps,
    double? weight,
    int? restTime,
  }) => PersonalWorkoutExercise(
    exerciseId: exerciseId ?? this.exerciseId,
    name: name ?? this.name,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
    restTime: restTime ?? this.restTime,
  );
}

@HiveType(typeId: 1)
class HivePersonalWorkout extends HiveObject {
  @HiveField(0)
  String workoutId;
  @HiveField(1)
  String name;
  @HiveField(2)
  String? description;
  @HiveField(3)
  List<HivePersonalWorkoutExercise> exercises;

  HivePersonalWorkout({
    required this.workoutId,
    required this.name,
    required this.description,
    required this.exercises,
  });

  factory HivePersonalWorkout.fromDomain(PersonalWorkout w) =>
      HivePersonalWorkout(
        workoutId: w.workoutId,
        name: w.name,
        description: w.description,
        exercises:
            w.exercises.map(HivePersonalWorkoutExercise.fromDomain).toList(),
      );

  PersonalWorkout toDomain() => PersonalWorkout(
    workoutId: workoutId,
    name: name,
    description: description,
    exercises: exercises.map((e) => e.toDomain()).toList(),
  );

  HivePersonalWorkout copyWith({
    String? workoutId,
    String? name,
    String? description,
    List<HivePersonalWorkoutExercise>? exercises,
  }) => HivePersonalWorkout(
    workoutId: workoutId ?? this.workoutId,
    name: name ?? this.name,
    description: description ?? this.description,
    exercises: exercises ?? this.exercises,
  );
}
