import 'package:hive/hive.dart';

import '../../../models/custom_workout.dart';
import '../../../models/workout.dart';
import '../../../models/workout_exercise.dart';
import '../../../models/workout_set.dart';

part 'hive_workout.g.dart';

@HiveType(typeId: 2)
class HiveWorkoutSet extends HiveObject {
  @HiveField(0)
  final int setNumber;
  @HiveField(1)
  final int reps;
  @HiveField(2)
  final double weight;
  @HiveField(3)
  final int timeMicros; // store as primitive for Hive

  HiveWorkoutSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.timeMicros,
  });

  factory HiveWorkoutSet.fromDomain(WorkoutSet set) => HiveWorkoutSet(
    setNumber: set.setNumber,
    reps: set.reps,
    weight: set.weight,
    timeMicros: set.time.inMicroseconds,
  );

  WorkoutSet toDomain() => WorkoutSet(
    setNumber: setNumber,
    reps: reps,
    weight: weight,
    time: Duration(microseconds: timeMicros),
  );
}

@HiveType(typeId: 3)
class HiveWorkoutExercise extends HiveObject {
  @HiveField(0)
  final String exerciseId;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? equipmentId;
  @HiveField(3)
  final String muscleGroup;
  @HiveField(4)
  final List<HiveWorkoutSet> sets;
  @HiveField(5)
  final DateTime startTime;
  @HiveField(6)
  DateTime? endTime;

  HiveWorkoutExercise({
    required this.exerciseId,
    required this.name,
    this.equipmentId,
    required this.muscleGroup,
    required this.sets,
    required this.startTime,
    this.endTime,
  });

  factory HiveWorkoutExercise.fromDomain(WorkoutExercise exercise) {
    return HiveWorkoutExercise(
      exerciseId: exercise.exerciseId,
      name: exercise.name,
      equipmentId: exercise.equipmentId,
      muscleGroup: exercise.muscleGroup,
      sets: exercise.sets.map((set) => HiveWorkoutSet.fromDomain(set)).toList(),
      startTime: exercise.startTime,
      endTime: exercise.endTime,
    );
  }

  WorkoutExercise toDomain() => WorkoutExercise(
    exerciseId: exerciseId,
    name: name,
    equipmentId: equipmentId,
    muscleGroup: muscleGroup,
    sets: sets.map((set) => set.toDomain()).toList(),
    startTime: startTime,
    endTime: endTime,
  );
}

@HiveType(typeId: 4)
class HiveWorkout extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? name;
  @HiveField(2)
  final String workoutType;
  @HiveField(3)
  final List<HiveWorkoutExercise> exercises;
  @HiveField(4)
  final DateTime startTime;
  @HiveField(5)
  DateTime? endTime;
  @HiveField(6)
  final bool isUploaded;
  @HiveField(7)
  final bool isOngoing;
  @HiveField(8)
  final bool createdWhileGuest;

  HiveWorkout({
    required this.id,
    required this.name,
    required this.workoutType,
    required this.exercises,
    required this.startTime,
    this.endTime,
    required this.isUploaded,
    required this.isOngoing,
    required this.createdWhileGuest,
  });

  factory HiveWorkout.fromDomain(Workout workout) {
    return HiveWorkout(
      id: workout.id,
      name: workout.name,
      workoutType: workout.workoutType.toString().split('.').last,
      exercises:
          workout.exercises
              .map((exercise) => HiveWorkoutExercise.fromDomain(exercise))
              .toList(),
      startTime: workout.startTime,
      endTime: workout.endTime,
      isUploaded: workout.isUploaded,
      isOngoing: workout.isOngoing,
      createdWhileGuest: workout.createdWhileGuest,
    );
  }

  Workout toDomain() => Workout(
    id: id,
    name: name,
    workoutType: WorkoutType.values.firstWhere(
      (e) => e.toString() == workoutType,
      orElse: () => WorkoutType.custom,
    ),
    exercises: exercises.map((exercise) => exercise.toDomain()).toList(),
    startTime: startTime,
    endTime: endTime,
    isUploaded: isUploaded,
    isOngoing: isOngoing,
    createdWhileGuest: createdWhileGuest,
  );
}
