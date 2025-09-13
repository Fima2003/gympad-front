part of 'questionnaire_bloc.dart';

class QuestionnaireState extends Equatable {
  final bool loading;
  final bool skipped;
  final bool completed;
  final int currentIndex;
  final int total;
  final Map<String, List<String>> answers;
  final String? error;

  const QuestionnaireState({
    required this.loading,
    required this.skipped,
    required this.completed,
    required this.currentIndex,
    required this.total,
    required this.answers,
    this.error,
  });

  factory QuestionnaireState.initial({int total = 12}) => QuestionnaireState(
    loading: true,
    skipped: false,
    completed: false,
    currentIndex: 0,
    total: total,
    answers: const {},
  );

  QuestionnaireState copyWith({
    bool? loading,
    bool? skipped,
    bool? completed,
    int? currentIndex,
    int? total,
    Map<String, List<String>>? answers,
    String? error,
  }) => QuestionnaireState(
    loading: loading ?? this.loading,
    skipped: skipped ?? this.skipped,
    completed: completed ?? this.completed,
    currentIndex: currentIndex ?? this.currentIndex,
    total: total ?? this.total,
    answers: answers ?? this.answers,
    error: error,
  );

  @override
  List<Object?> get props => [
    loading,
    skipped,
    completed,
    currentIndex,
    total,
    answers,
    error,
  ];
}
