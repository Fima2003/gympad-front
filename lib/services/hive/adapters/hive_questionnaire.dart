import 'package:hive/hive.dart';

import '../../../models/questionnaire.dart';

part 'hive_questionnaire.g.dart';

/// Manual Hive adapter for storing questionnaire status and answers.
/// We avoid code-gen here to keep things simple and explicit.
@HiveType(typeId: 8)
class HiveQuestionnaire extends HiveObject {
  @HiveField(0)
  final bool skipped;
  @HiveField(1)
  final bool completed;
  @HiveField(2)
  final DateTime? completedAt;
  @HiveField(3)
  final Map<String, List<String>> answers;
  @HiveField(4)
  final bool uploaded;

  HiveQuestionnaire({
    this.skipped = false,
    this.completed = false,
    this.completedAt,
    Map<String, List<String>>? answers,
    this.uploaded = false,
  }) : answers = answers ?? const {};

  HiveQuestionnaire copyWith({
    bool? skipped,
    bool? completed,
    DateTime? completedAt,
    Map<String, List<String>>? answers,
    bool? uploaded,
  }) {
    return HiveQuestionnaire(
      skipped: skipped ?? this.skipped,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      answers: answers ?? this.answers,
      uploaded: uploaded ?? this.uploaded,
    );
  }

  Questionnaire toDomain() => Questionnaire(
    skipped: skipped,
    completed: completed,
    completedAt: completedAt,
    answers: answers,
    uploaded: uploaded,
  );

  factory HiveQuestionnaire.fromDomain(Questionnaire q) {
    return HiveQuestionnaire(
      skipped: q.skipped,
      completed: q.completed,
      completedAt: q.completedAt,
      answers: q.answers,
      uploaded: q.uploaded,
    );
  }
}
