part of 'questionnaire_bloc.dart';

abstract class QuestionnaireEvent extends Equatable {
  const QuestionnaireEvent();
  @override
  List<Object?> get props => [];
}

class QuestionnaireStarted extends QuestionnaireEvent {
  final bool forceRefresh;
  const QuestionnaireStarted({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class QuestionnaireSkipped extends QuestionnaireEvent {}

class QuestionnaireAnswerUpdated extends QuestionnaireEvent {
  final String questionId;
  final List<String> selectedOptions;
  const QuestionnaireAnswerUpdated({
    required this.questionId,
    required this.selectedOptions,
  });

  @override
  List<Object?> get props => [questionId, selectedOptions];
}

class QuestionnaireSubmitted extends QuestionnaireEvent {}

class QuestionnaireProgressChanged extends QuestionnaireEvent {
  final int index; // zero-based
  const QuestionnaireProgressChanged(this.index);
  @override
  List<Object?> get props => [index];
}

class QuestionnaireSetTotal extends QuestionnaireEvent {
  final int total;
  const QuestionnaireSetTotal(this.total);
  @override
  List<Object?> get props => [total];
}
