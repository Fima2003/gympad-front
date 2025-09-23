import 'package:gympad/services/api/api.dart';
import 'package:gympad/services/hive/adapters/hive_questionnaire.dart';
import 'package:gympad/services/hive/questionnaire_lss.dart';

/// Service facade that coordinates questionnaire persistence (Hive) and network (API).
/// BLoC should depend only on this service, not on storage or API directly.
class QuestionnaireService {
  static final QuestionnaireService _instance =
      QuestionnaireService._internal();
  factory QuestionnaireService() => _instance;
  QuestionnaireService._internal();

  final QuestionnaireLocalStorageService _lss =
      QuestionnaireLocalStorageService();
  final QuestionnaireApiService _api = QuestionnaireApiService();
  final HiveQuestionnaire q = HiveQuestionnaire();

  // Load current questionnaire state from local storage
  Future<HiveQuestionnaire?> load() => _lss.load();

  // Update answers locally
  Future<void> upsertAnswers(Map<String, List<String>> answers) async {
    await _lss.upsertAnswers(answers);
  }

  // Mark skipped locally and attempt to submit; mark uploaded flag accordingly
  Future<void> markSkippedAndSubmit() async {
    await _lss.markSkipped();
  }

  Future<void> markCompleted(bool completed) async {
    final cur = await _lss.load();
    if (cur != null) {
      await _lss.save(cur.copyWith(completed: completed));
    }
  }

  // Mark completed locally and attempt to submit; mark uploaded flag accordingly
  Future<void> markCompletedAndSubmit() async {
    final stored = await _lss.markCompleted();
    final req = QuestionnaireSubmitRequest(
      completedAt: stored.completedAt,
      answers: stored.answers,
    );
    final resp = await _api.submit(req);
    final cur = await _lss.load();
    if (cur != null) {
      await _lss.save(cur.copyWith(uploaded: resp.success));
    }
  }

  // Retry upload if locally completed/skipped and not uploaded yet
  Future<void> retryIfPendingUpload() async {
    final stored = await _lss.load();
    if (stored == null) return;
    if (stored.completed && !stored.uploaded) {
      final req = QuestionnaireSubmitRequest(
        completedAt: stored.completedAt,
        answers: stored.answers,
      );
      final resp = await _api.submit(req);
      if (resp.success) {
        await _lss.save(stored.copyWith(uploaded: true));
      }
    }
  }

  Future<void> clear() async {
    await _lss.clear();
  }
}
