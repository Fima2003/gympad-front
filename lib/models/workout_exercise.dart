import 'package:equatable/equatable.dart';

import 'workout_set.dart';

class WorkoutExercise extends Equatable {
  final String exerciseId;
  final String name;
  final String? equipmentId;
  final String muscleGroup;
  final List<WorkoutSet> sets;
  final DateTime startTime;
  final DateTime? endTime;

  const WorkoutExercise({
    required this.exerciseId,
    required this.name,
    this.equipmentId,
    required this.muscleGroup,
    required this.sets,
    required this.startTime,
    this.endTime,
  });

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  double get averageWeight {
    if (sets.isEmpty) return 0.0;
    return sets.map((set) => set.weight).reduce((a, b) => a + b) / sets.length;
  }

  int get totalSets => sets.length;

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'equipmentId': equipmentId,
      'muscleGroup': muscleGroup,
      'sets': sets.map((set) => set.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exerciseId'] ?? '',
      name: json['name'] ?? '',
      equipmentId: json['equipmentId'],
      muscleGroup: json['muscleGroup'] ?? '',
      sets:
          (json['sets'] as List?)
              ?.map((setJson) => WorkoutSet.fromJson(setJson))
              .toList() ??
          [],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    );
  }

  WorkoutExercise copyWith({
    String? exerciseId,
    String? name,
    String? equipmentId,
    String? muscleGroup,
    List<WorkoutSet>? sets,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      equipmentId: equipmentId ?? this.equipmentId,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      sets: sets ?? this.sets,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [
    exerciseId,
    name,
    equipmentId,
    muscleGroup,
    sets,
    startTime,
    endTime,
  ];
}
