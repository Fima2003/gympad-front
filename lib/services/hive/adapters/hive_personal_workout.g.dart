// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_personal_workout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HivePersonalWorkoutExerciseAdapter
    extends TypeAdapter<HivePersonalWorkoutExercise> {
  @override
  final int typeId = 0;

  @override
  HivePersonalWorkoutExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePersonalWorkoutExercise(
      exerciseId: fields[0] as String,
      name: fields[1] as String,
      sets: fields[2] as int,
      weight: fields[3] as double,
      reps: fields[4] as int,
      restTime: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HivePersonalWorkoutExercise obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sets)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.reps)
      ..writeByte(5)
      ..write(obj.restTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePersonalWorkoutExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HivePersonalWorkoutAdapter extends TypeAdapter<HivePersonalWorkout> {
  @override
  final int typeId = 1;

  @override
  HivePersonalWorkout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePersonalWorkout(
      name: fields[0] as String,
      description: fields[1] as String?,
      exercises: (fields[2] as List).cast<HivePersonalWorkoutExercise>(),
    );
  }

  @override
  void write(BinaryWriter writer, HivePersonalWorkout obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.exercises);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePersonalWorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
