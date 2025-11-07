import 'package:gympad/services/api/api.dart';
import 'package:gympad/services/hive/questionnaire_lss.dart';

import '../models/withAdapters/questionnaire.dart';
import '../models/withAdapters/user.dart';
import 'hive/lss.dart';
import 'hive/user_auth_lss.dart';

/// Service facade that coordinates questionnaire persistence (Hive) and network (API).
/// BLoC should depend only on this service, not on storage or API directly.
class QuestionnaireService {
  static final QuestionnaireService _instance =
      QuestionnaireService._internal();
  factory QuestionnaireService() => _instance;
  QuestionnaireService._internal();

  final QuestionnaireLocalStorageService _lss =
      QuestionnaireLocalStorageService();
  final LSS<User, User> _authLss = UserAuthLocalStorageService();
  final QuestionnaireApiService _api = QuestionnaireApiService();

  // Load current questionnaire state from local storage
  Future<Questionnaire?> load() => _lss.get();

  // Update answers locally
  Future<void> upsertAnswers(Map<String, List<String>> answers) async {
    await _lss.upsertAnswers(answers);
  }

  // Mark skipped locally and attempt to submit; mark uploaded flag accordingly
  Future<void> markSkippedAndSubmit() async {
    await _lss.markSkipped();
  }

  Future<void> markCompleted(bool completed) async {
    final cur = await _lss.get();
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
    final cur = await _lss.get();
    UserLevel userLevel;
    String goal;
    switch (stored.answers['user_level']?.first) {
      case "Beginner":
        userLevel = UserLevel.beginner;
        break;
      case "Intermediate":
        userLevel = UserLevel.intermediate;
        break;
      case "Advanced":
        userLevel = UserLevel.advanced;
        break;
      default:
        userLevel = UserLevel.beginner;
    }
    switch (stored.answers['user_goal']?.first) {
      case "Increase muscle size (Hypertrophy)":
        goal = "hypertrophy";
        break;
      case "Increase strength (Lifting heavier weights)":
        goal = "strength";
        break;
      case "Improve cardiovascular endurance":
        goal = "endurance";
        break;
      case "Lose weight / Fat loss":
        goal = "fatLoss";
        break;
      case "Improve overall health and fitness":
        goal = "generalFitness";
        break;
      case "Recover from an injury (Rehabilitation)":
        goal = "rehabilitation";
        break;
      default:
        goal = "generalFitness";
        break;
    }
    _authLss.update(
      copyWithFn: (User u) {
        return u.copyWith(level: userLevel, goal: goal);
      },
    );
    if (cur != null) {
      await _lss.save(cur.copyWith(uploaded: resp.success));
    }
  }

  // Retry upload if locally completed/skipped and not uploaded yet
  Future<void> retryIfPendingUpload() async {
    final stored = await _lss.get();
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
