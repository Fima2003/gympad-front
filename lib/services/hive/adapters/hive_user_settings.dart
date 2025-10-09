import 'package:hive/hive.dart';

import '../../../models/user_settings.dart';

part 'hive_user_settings.g.dart';

@HiveType(typeId: 9)
class HiveUserSettings {
  @HiveField(0)
  final String weightUnit; // e.g., "kg" or "lbs"

  HiveUserSettings({required this.weightUnit});

  UserSettings toDomain() => UserSettings(weightUnit: weightUnit);

  factory HiveUserSettings.fromDomain(UserSettings domain) =>
      HiveUserSettings(weightUnit: domain.weightUnit);
}
