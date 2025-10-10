// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 1;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      exerciseId: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as String,
      equipmentId: fields[4] as String?,
      muscleGroup: (fields[5] as List).cast<String>(),
      restTime: fields[6] as int,
      minReps: fields[7] as int,
      maxReps: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.equipmentId)
      ..writeByte(5)
      ..write(obj.muscleGroup)
      ..writeByte(6)
      ..write(obj.restTime)
      ..writeByte(7)
      ..write(obj.minReps)
      ..writeByte(8)
      ..write(obj.maxReps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
