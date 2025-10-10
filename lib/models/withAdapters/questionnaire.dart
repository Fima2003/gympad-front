import 'package:hive/hive.dart';

part 'questionnaire.g.dart';

@HiveType(typeId: 8)
class Questionnaire extends HiveObject {
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

  Questionnaire({
    this.skipped = false,
    this.completed = false,
    this.completedAt,
    Map<String, List<String>>? answers,
    this.uploaded = false,
  }) : answers = answers ?? const {};

  Questionnaire copyWith({
    bool? skipped,
    bool? completed,
    DateTime? completedAt,
    Map<String, List<String>>? answers,
    bool? uploaded,
  }) {
    return Questionnaire(
      skipped: skipped ?? this.skipped,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      answers: answers ?? this.answers,
      uploaded: uploaded ?? this.uploaded,
    );
  }
}
