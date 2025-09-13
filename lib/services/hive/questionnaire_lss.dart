import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/hive_questionnaire.dart';
import 'hive_initializer.dart';
import 'package:gympad/services/logger_service.dart';

class QuestionnaireLocalStorageService {
  static const String _boxName = 'questionnaire_box';
  static const String _key = 'status';

  Future<Box<HiveQuestionnaire>> _box() async {
    await HiveInitializer.init();
    try {
      return Hive.isBoxOpen(_boxName)
          ? Hive.box<HiveQuestionnaire>(_boxName)
          : await Hive.openBox<HiveQuestionnaire>(_boxName);
    } catch (e, st) {
      // Attempt recovery from incompatible/corrupted box by deleting and reopening
      final logger = AppLogger();
      logger.error('Questionnaire box open failed, recovering', e, st);
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        logger.warning('Deleted questionnaire box from disk, reopening');
      } catch (delErr, delSt) {
        logger.error(
          'Failed deleting questionnaire box from disk',
          delErr,
          delSt,
        );
      }
      // Reopen a fresh box (will be empty)
      return await Hive.openBox<HiveQuestionnaire>(_boxName);
    }
  }

  Future<HiveQuestionnaire?> load() async {
    try {
      final box = await _box();
      return box.get(_key);
    } catch (e, st) {
      AppLogger().error('QuestionnaireLocalStorageService.load failed', e, st);
      return null;
    }
  }

  Future<void> save(HiveQuestionnaire value) async {
    try {
      final box = await _box();
      await box.put(_key, value);
    } catch (e, st) {
      AppLogger().error('QuestionnaireLocalStorageService.save failed', e, st);
      rethrow;
    }
  }

  Future<void> markSkipped() async {
    final current = await load();
    await save((current ?? HiveQuestionnaire()).copyWith(skipped: true));
  }

  Future<void> upsertAnswers(Map<String, List<String>> answers) async {
    final current = await load();
    final merged = Map<String, List<String>>.from(current?.answers ?? {});
    for (final entry in answers.entries) {
      merged[entry.key] = List<String>.from(entry.value);
    }
    await save((current ?? HiveQuestionnaire()).copyWith(answers: merged));
  }

  Future<HiveQuestionnaire> markCompleted() async {
    final current = await load();
    final toSave = (current ?? HiveQuestionnaire()).copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );
    await save(toSave);
    return toSave;
  }

  Future<void> clear() async {
    try {
      final box = await _box();
      await box.delete(_key);
    } catch (e, st) {
      AppLogger().error('QuestionnaireLocalStorageService.clear failed', e, st);
      rethrow;
    }
  }
}
