class Questionnaire {
  final bool skipped;
  final bool completed;
  final DateTime? completedAt;
  final Map<String, List<String>> answers;
  final bool uploaded;

  Questionnaire({
    this.skipped = false,
    this.completed = false,
    this.completedAt,
    Map<String, List<String>>? answers,
    this.uploaded = false,
  }) : answers = answers ?? const {};

  Questionnaire copyWith({
    bool? skipped,
    bool? completed,
    DateTime? completedAt,
    Map<String, List<String>>? answers,
    bool? uploaded,
  }) {
    return Questionnaire(
      skipped: skipped ?? this.skipped,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      answers: answers ?? this.answers,
      uploaded: uploaded ?? this.uploaded,
    );
  }
}
