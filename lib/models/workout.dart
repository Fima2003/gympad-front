import 'workout_exercise.dart';

class Workout {
  final String id;
  final String? name;
  final List<WorkoutExercise> exercises;
  final DateTime startTime;
  DateTime? endTime;
  final bool isUploaded;
  final bool isOngoing;
  final bool createdWhileGuest; // Marker for workouts created without auth

  /// Returns true if this workout is a free workout (no predefined name/id pattern)
  bool get isFreeWorkout {
    // Heuristic: free workouts have id starting with 'free_' or no name
    return id.startsWith('free_') || (name == null || name!.isEmpty);
  }

  Workout({
    required this.id,
    this.name,
    required this.exercises,
    required this.startTime,
    this.endTime,
    this.isUploaded = false,
    this.isOngoing = true,
  this.createdWhileGuest = false,
  });

  Duration get totalDuration {
    if (endTime == null) return DateTime.now().difference(startTime);
    return endTime!.difference(startTime);
  }

  int get totalExercises => exercises.length;

  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.totalSets);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isUploaded': isUploaded,
      'isOngoing': isOngoing,
  'createdWhileGuest': createdWhileGuest,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] ?? '',
      name: json['name'],
      exercises:
          (json['exercises'] as List?)
              ?.map((exerciseJson) => WorkoutExercise.fromJson(exerciseJson))
              .toList() ??
          [],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isUploaded: json['isUploaded'] ?? false,
      isOngoing: json['isOngoing'] ?? true,
  createdWhileGuest: json['createdWhileGuest'] ?? false,
    );
  }

  Workout copyWith({
    String? id,
    String? name,
    List<WorkoutExercise>? exercises,
    DateTime? startTime,
    DateTime? endTime,
    bool? isUploaded,
    bool? isOngoing,
    bool? createdWhileGuest,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isUploaded: isUploaded ?? this.isUploaded,
      isOngoing: isOngoing ?? this.isOngoing,
      createdWhileGuest: createdWhileGuest ?? this.createdWhileGuest,
    );
  }
}
