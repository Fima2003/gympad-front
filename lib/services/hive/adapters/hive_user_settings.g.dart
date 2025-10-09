// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveUserSettingsAdapter extends TypeAdapter<HiveUserSettings> {
  @override
  final int typeId = 9;

  @override
  HiveUserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveUserSettings(
      weightUnit: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUserSettings obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.weightUnit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveUserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
