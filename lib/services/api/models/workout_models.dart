/// Models for Workout Cloud Functions API
class WorkoutListItem {
  final String id;
  final String? name;
  final List<String> muscleGroups;

  WorkoutListItem({required this.id, this.name, required this.muscleGroups});

  factory WorkoutListItem.fromJson(Map<String, dynamic> json) {
    return WorkoutListItem(
      id: json['id'] as String,
      name: json['name'] as String?,
      muscleGroups:
          (json['muscleGroups'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'muscleGroups': muscleGroups,
  };
}

class WorkoutSetDto {
  final int setNumber;
  final int reps;
  final double weight;
  final int time; // seconds

  WorkoutSetDto({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.time,
  });

  factory WorkoutSetDto.fromJson(Map<String, dynamic> json) {
    return WorkoutSetDto(
      setNumber: (json['setNumber'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      time: (json['time'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'reps': reps,
    'weight': weight,
    'time': time,
  };
}

class PersonalWorkoutExerciseDto {
  final String exerciseId;
  final String name;
  final int sets;
  final double weight;
  final int reps;
  final int restTime;

  PersonalWorkoutExerciseDto({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restTime,
  });

  factory PersonalWorkoutExerciseDto.fromJson(Map<String, dynamic> json) {
    return PersonalWorkoutExerciseDto(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      restTime: (json['restTime'] as num).toInt(),
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

class WorkoutExerciseDto {
  final String exerciseId;
  final String name;
  final String? equipmentId;
  final String muscleGroup;
  final List<WorkoutSetDto> sets;
  final DateTime startTime;
  final DateTime? endTime;

  WorkoutExerciseDto({
    required this.exerciseId,
    required this.name,
    this.equipmentId,
    required this.muscleGroup,
    required this.sets,
    required this.startTime,
    this.endTime,
  });

  factory WorkoutExerciseDto.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseDto(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      equipmentId: json['equipmentId'] as String?,
      muscleGroup: json['muscleGroup'] as String,
      sets:
          (json['sets'] as List<dynamic>? ?? const [])
              .map((e) => WorkoutSetDto.fromJson(e as Map<String, dynamic>))
              .toList(),
      startTime:
          json['startTime'] != null
              ? DateTime.parse(json['startTime'] as String)
              : DateTime.fromMillisecondsSinceEpoch(0),
      endTime:
          json['endTime'] != null
              ? DateTime.parse(json['endTime'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'equipmentId': equipmentId,
    'muscleGroup': muscleGroup,
    'sets': sets.map((e) => e.toJson()).toList(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
  };
}

class WorkoutDetailResponse {
  final String id;
  final String? name;
  final List<WorkoutExerciseDto> exercises;
  final DateTime startTime;
  final DateTime endTime;

  WorkoutDetailResponse({
    required this.id,
    this.name,
    required this.exercises,
    required this.startTime,
    required this.endTime,
  });

  factory WorkoutDetailResponse.fromJson(Map<String, dynamic> json) {
    return WorkoutDetailResponse(
      id: json['id'] as String,
      name: json['name'] as String?,
      exercises:
          (json['exercises'] as List<dynamic>? ?? const [])
              .map(
                (e) => WorkoutExerciseDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
  };
}

class PersonalWorkoutResponse extends CreatePersonalWorkoutRequest {
  PersonalWorkoutResponse({
    required super.name,
    super.description,
    required super.exercises,
  });

  factory PersonalWorkoutResponse.fromJson(Map<String, dynamic> json) {
    return PersonalWorkoutResponse(
      name: json['name'] as String,
      description: json['description'] as String?,
      exercises:
          (json['exercises'] as List<dynamic>? ?? const [])
              .map(
                (e) => PersonalWorkoutExerciseDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return CreatePersonalWorkoutRequest(
      name: name,
      description: description,
      exercises: exercises,
    ).toJson();
  }
}

class CreatePersonalWorkoutRequest {
  final String name;
  final String? description;
  final List<PersonalWorkoutExerciseDto> exercises;

  CreatePersonalWorkoutRequest({
    required this.exercises,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory CreatePersonalWorkoutRequest.fromJson(Map<String, dynamic> json) {
    return CreatePersonalWorkoutRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      exercises:
          (json['exercises'] as List<dynamic>? ?? const [])
              .map(
                (e) => PersonalWorkoutExerciseDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}

class WorkoutCreateRequest {
  final String id;
  final String? name;
  final List<WorkoutExerciseDto> exercises;
  final DateTime startTime;
  final DateTime endTime;

  WorkoutCreateRequest({
    required this.id,
    this.name,
    required this.exercises,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
  };
}

class WorkoutDeleteRequest {
  final String workoutId;

  WorkoutDeleteRequest({required this.workoutId});

  Map<String, dynamic> toJson() => {'workoutId': workoutId};
}
