// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveUserAuthAdapter extends TypeAdapter<HiveUserAuth> {
  @override
  final int typeId = 5;

  @override
  HiveUserAuth read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveUserAuth(
      userId: fields[0] as String?,
      gymId: fields[1] as String?,
      authToken: fields[2] as String?,
      isGuest: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUserAuth obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.gymId)
      ..writeByte(2)
      ..write(obj.authToken)
      ..writeByte(3)
      ..write(obj.isGuest);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveUserAuthAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
