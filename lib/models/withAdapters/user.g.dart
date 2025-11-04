// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 5;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      userId: fields[0] as String?,
      gymId: fields[1] as String?,
      authToken: fields[2] as String?,
      level: fields[4] as UserLevel?,
      isGuest: fields[3] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.gymId)
      ..writeByte(2)
      ..write(obj.authToken)
      ..writeByte(3)
      ..write(obj.isGuest)
      ..writeByte(4)
      ..write(obj.level);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserLevelAdapter extends TypeAdapter<UserLevel> {
  @override
  final int typeId = 11;

  @override
  UserLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserLevel.beginner;
      case 1:
        return UserLevel.intermediate;
      case 2:
        return UserLevel.advanced;
      default:
        return UserLevel.beginner;
    }
  }

  @override
  void write(BinaryWriter writer, UserLevel obj) {
    switch (obj) {
      case UserLevel.beginner:
        writer.writeByte(0);
        break;
      case UserLevel.intermediate:
        writer.writeByte(1);
        break;
      case UserLevel.advanced:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
