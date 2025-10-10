// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'questionnaire.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionnaireAdapter extends TypeAdapter<Questionnaire> {
  @override
  final int typeId = 8;

  @override
  Questionnaire read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Questionnaire(
      skipped: fields[0] as bool,
      completed: fields[1] as bool,
      completedAt: fields[2] as DateTime?,
      answers: (fields[3] as Map?)?.map(
        (dynamic k, dynamic v) =>
            MapEntry(k as String, (v as List).cast<String>()),
      ),
      uploaded: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Questionnaire obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.skipped)
      ..writeByte(1)
      ..write(obj.completed)
      ..writeByte(2)
      ..write(obj.completedAt)
      ..writeByte(3)
      ..write(obj.answers)
      ..writeByte(4)
      ..write(obj.uploaded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionnaireAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
