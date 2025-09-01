// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_custom_workout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveCustomWorkoutExerciseAdapter
    extends TypeAdapter<HiveCustomWorkoutExercise> {
  @override
  final int typeId = 6;

  @override
  HiveCustomWorkoutExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCustomWorkoutExercise(
      id: fields[0] as String,
      setsAmount: fields[1] as int,
      suggestedWeight: fields[2] as double?,
      restTime: fields[3] as int,
      suggestedReps: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCustomWorkoutExercise obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.setsAmount)
      ..writeByte(2)
      ..write(obj.suggestedWeight)
      ..writeByte(3)
      ..write(obj.restTime)
      ..writeByte(4)
      ..write(obj.suggestedReps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCustomWorkoutExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveCustomWorkoutAdapter extends TypeAdapter<HiveCustomWorkout> {
  @override
  final int typeId = 7;

  @override
  HiveCustomWorkout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCustomWorkout(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      difficulty: fields[3] as String,
      muscleGroups: (fields[4] as List).cast<String>(),
      imageUrl: fields[5] as String?,
      exercises: (fields[6] as List).cast<HiveCustomWorkoutExercise>(),
      estimatedCalories: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCustomWorkout obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.difficulty)
      ..writeByte(4)
      ..write(obj.muscleGroups)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.exercises)
      ..writeByte(7)
      ..write(obj.estimatedCalories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCustomWorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
