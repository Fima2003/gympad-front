import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 9)
class UserSettings extends HiveObject {
  @HiveField(0)
  final String weightUnit;

  UserSettings({required this.weightUnit});

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(weightUnit: json['weightUnit']);
  }

  UserSettings copyWith({String? weightUnit}) =>
      UserSettings(weightUnit: weightUnit ?? this.weightUnit);
}
