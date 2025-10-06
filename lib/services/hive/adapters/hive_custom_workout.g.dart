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
      name: fields[5] as String,
      setsAmount: fields[1] as int,
      suggestedWeight: fields[2] as double?,
      restTime: fields[3] as int,
      suggestedReps: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCustomWorkoutExercise obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.setsAmount)
      ..writeByte(2)
      ..write(obj.suggestedWeight)
      ..writeByte(3)
      ..write(obj.restTime)
      ..writeByte(4)
      ..write(obj.suggestedReps)
      ..writeByte(5)
      ..write(obj.name);
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
      workoutType: fields[2] as String,
      description: fields[3] as String,
      difficulty: fields[4] as String,
      muscleGroups: (fields[5] as List).cast<String>(),
      imageUrl: fields[6] as String?,
      exercises: (fields[7] as List).cast<HiveCustomWorkoutExercise>(),
      estimatedCalories: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCustomWorkout obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.workoutType)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.difficulty)
      ..writeByte(5)
      ..write(obj.muscleGroups)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.exercises)
      ..writeByte(8)
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
