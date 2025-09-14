class QuestionnaireSubmitRequest {
  final DateTime? completedAt;
  final Map<String, List<String>> answers;

  QuestionnaireSubmitRequest({this.completedAt, required this.answers});

  Map<String, dynamic> toJson() => {
    'completedAt': completedAt?.toIso8601String(),
    'answers': answers,
  };
}
