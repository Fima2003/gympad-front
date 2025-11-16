// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_notification_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveNotificationSettingsAdapter
    extends TypeAdapter<HiveNotificationSettings> {
  @override
  final int typeId = 10;

  @override
  HiveNotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveNotificationSettings(
      enabled: fields[0] as bool,
      workoutRemindersEnabled: fields[1] as bool,
      motivationalEnabled: fields[2] as bool,
      workoutReminderHour: fields[3] as int,
      workoutReminderMinute: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveNotificationSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.workoutRemindersEnabled)
      ..writeByte(2)
      ..write(obj.motivationalEnabled)
      ..writeByte(3)
      ..write(obj.workoutReminderHour)
      ..writeByte(4)
      ..write(obj.workoutReminderMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveNotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
