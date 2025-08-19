class WorkoutSet {
  final int setNumber;
  final int reps;
  final double weight;
  final Duration time;

  WorkoutSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'time': time.inSeconds,
    };
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      setNumber: json['setNumber'] ?? 0,
      reps: json['reps'] ?? 0,
      weight: json['weight']?.toDouble() ?? 0.0,
      time: Duration(seconds: json['time'] ?? 0),
    );
  }
  WorkoutSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    Duration? time,
  }) {
    return WorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      time: time ?? this.time,
    );
  }
}
