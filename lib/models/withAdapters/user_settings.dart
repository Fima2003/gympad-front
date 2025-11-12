import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 9)
class UserSettings extends HiveObject {
  @HiveField(0)
  final String weightUnit;
  @HiveField(1)
  final String? etag;

  UserSettings({required this.weightUnit, this.etag});

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      weightUnit: json['weightUnit'],
      etag: json['etag'] as String?,
    );
  }

  UserSettings copyWith({String? weightUnit, String? etag}) => UserSettings(
    weightUnit: weightUnit ?? this.weightUnit,
    etag: etag ?? this.etag,
  );
}
