import '../../models/withAdapters/questionnaire.dart';
import 'package:gympad/services/logger_service.dart';

import 'lss.dart';

class QuestionnaireLocalStorageService
    extends LSS<Questionnaire, Questionnaire> {
  final logger = AppLogger();
  static const String _defaultKey = 'status';

  QuestionnaireLocalStorageService()
    : super('questionnaire_box', defaultKey: _defaultKey);

  @override
  Questionnaire toDomain(Questionnaire hive) => hive;

  @override
  Questionnaire fromDomain(Questionnaire domain) => domain;

  @override
  getKey(Questionnaire domain) => _defaultKey;

  Future<void> markSkipped() async {
    final current = await get();
    await save((current ?? Questionnaire()).copyWith(skipped: true));
  }

  Future<void> upsertAnswers(Map<String, List<String>> answers) async {
    final current = await get();
    final merged = Map<String, List<String>>.from(current?.answers ?? {});
    for (final entry in answers.entries) {
      merged[entry.key] = List<String>.from(entry.value);
    }
    await save((current ?? Questionnaire()).copyWith(answers: merged));
  }

  Future<Questionnaire> markCompleted() async {
    final current = await get();
    final toSave = (current ?? Questionnaire()).copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );
    await save(toSave);
    return toSave;
  }
}
