import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/services/questionnaire_service.dart';

part 'questionnaire_event.dart';
part 'questionnaire_state.dart';

class QuestionnaireBloc extends Bloc<QuestionnaireEvent, QuestionnaireState> {
  final QuestionnaireService _service;

  QuestionnaireBloc({QuestionnaireService? service})
    : _service = service ?? QuestionnaireService(),
      super(QuestionnaireState.initial()) {
    on<QuestionnaireStarted>(_onStarted);
    on<QuestionnaireSkipped>(_onSkipped);
    on<QuestionnaireAnswerUpdated>(_onAnswerUpdated);
    on<QuestionnaireSubmitted>(_onSubmitted);
    on<QuestionnaireProgressChanged>(_onProgressChanged);
    on<QuestionnaireSetTotal>(_onSetTotal);
  }

  Future<void> _onStarted(
    QuestionnaireStarted event,
    Emitter<QuestionnaireState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final stored = await _service.load();
    if (stored != null) {
      emit(
        state.copyWith(
          loading: false,
          skipped: event.forceRefresh ? false : stored.skipped,
          completed: stored.completed,
          answers: stored.answers,
        ),
      );
      // Retry submit if it was completed/skipped but not uploaded yet
      await _service.retryIfPendingUpload();
    } else {
      emit(state.copyWith(loading: false));
    }
  }

  void _onProgressChanged(
    QuestionnaireProgressChanged event,
    Emitter<QuestionnaireState> emit,
  ) {
    emit(state.copyWith(currentIndex: event.index));
  }

  void _onSetTotal(
    QuestionnaireSetTotal event,
    Emitter<QuestionnaireState> emit,
  ) {
    emit(state.copyWith(total: event.total));
  }

  Future<void> _onSkipped(
    QuestionnaireSkipped event,
    Emitter<QuestionnaireState> emit,
  ) async {
    await _service.markSkippedAndSubmit();
    // Regardless of network result, state becomes skipped; error is non-blocking
    emit(state.copyWith(skipped: true));
  }

  Future<void> _onAnswerUpdated(
    QuestionnaireAnswerUpdated event,
    Emitter<QuestionnaireState> emit,
  ) async {
    final updated = Map<String, List<String>>.from(state.answers);
    updated[event.questionId] = List<String>.from(event.selectedOptions);
    await _service.upsertAnswers({event.questionId: event.selectedOptions});
    emit(state.copyWith(answers: updated));
  }

  Future<void> _onSubmitted(
    QuestionnaireSubmitted event,
    Emitter<QuestionnaireState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    await _service.markCompletedAndSubmit();
    // Regardless of network result, consider completed; error is non-blocking
    emit(state.copyWith(loading: false, completed: true));
  }
}
