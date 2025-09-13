// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_workout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveWorkoutSetAdapter extends TypeAdapter<HiveWorkoutSet> {
  @override
  final int typeId = 2;

  @override
  HiveWorkoutSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveWorkoutSet(
      setNumber: fields[0] as int,
      reps: fields[1] as int,
      weight: fields[2] as double,
      timeMicros: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveWorkoutSet obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.setNumber)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.timeMicros);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveWorkoutSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveWorkoutExerciseAdapter extends TypeAdapter<HiveWorkoutExercise> {
  @override
  final int typeId = 3;

  @override
  HiveWorkoutExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveWorkoutExercise(
      exerciseId: fields[0] as String,
      name: fields[1] as String,
      equipmentId: fields[2] as String?,
      muscleGroup: fields[3] as String,
      sets: (fields[4] as List).cast<HiveWorkoutSet>(),
      startTime: fields[5] as DateTime,
      endTime: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveWorkoutExercise obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.equipmentId)
      ..writeByte(3)
      ..write(obj.muscleGroup)
      ..writeByte(4)
      ..write(obj.sets)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveWorkoutExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveWorkoutAdapter extends TypeAdapter<HiveWorkout> {
  @override
  final int typeId = 4;

  @override
  HiveWorkout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveWorkout(
      id: fields[0] as String,
      name: fields[1] as String?,
      exercises: (fields[2] as List).cast<HiveWorkoutExercise>(),
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime?,
      isUploaded: fields[5] as bool,
      isOngoing: fields[6] as bool,
      createdWhileGuest: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveWorkout obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.exercises)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.isUploaded)
      ..writeByte(6)
      ..write(obj.isOngoing)
      ..writeByte(7)
      ..write(obj.createdWhileGuest);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveWorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
