class QuestionnaireSubmitRequest {
  final bool skipped;
  final bool completed;
  final DateTime? completedAt;
  final Map<String, List<String>> answers;

  QuestionnaireSubmitRequest({
    required this.skipped,
    required this.completed,
    this.completedAt,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
    'skipped': skipped,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'answers': answers,
  };
}
