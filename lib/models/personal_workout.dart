import '../blocs/data/data_bloc.dart';
import '../services/api/models/personal_workout.model.dart';
import 'custom_workout.dart';
import 'exercise.dart';

class PersonalWorkout {
  final String workoutId;
  final String name;
  final String? description;
  final List<PersonalWorkoutExercise> exercises;

  PersonalWorkout({
    required this.workoutId,
    required this.name,
    this.description = '',
    required this.exercises,
  });

  // Derive muscle groups from associated exercises (exercise metadata is now resolved externally)
  List<String> getMuscleGroups(DataState? state) {
    if (state is! DataReady) return [];
    final set = <String>{};
    for (final exercise in exercises) {
      final mg =
          state.exercises.values
              .firstWhere(
                (Exercise e) => e.id == exercise.exerciseId,
                orElse:
                    () => Exercise(
                      id: '',
                      name: '',
                      description: '',
                      muscleGroup: '',
                      image: '',
                      equipmentId: '',
                    ),
              )
              .muscleGroup;
      if (mg.isNotEmpty) set.add(mg);
    }
    return set.toList();
  }

  CustomWorkout toCustomWorkout(DataReady? state) => CustomWorkout(
    id: workoutId,
    name: name,
    workoutType: WorkoutType.personal,
    description: description ?? "",
    difficulty: 'none',
    muscleGroups: getMuscleGroups(state),
    imageUrl: '',
    exercises:
        exercises.map((e) {
          return CustomWorkoutExercise(
            id: e.exerciseId,
            name: e.name,
            setsAmount: e.sets,
            suggestedWeight: e.weight,
            restTime: e.restTime,
            suggestedReps: e.reps,
          );
        }).toList(),
    estimatedCalories: 0,
  );

  factory PersonalWorkout.fromJson(Map<String, dynamic> json) {
    return PersonalWorkout(
      workoutId: json['workoutId'] as String,
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
      workoutId: e.workoutId,
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

  // Muscle group lookups handled via DataBloc outside of model.

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
