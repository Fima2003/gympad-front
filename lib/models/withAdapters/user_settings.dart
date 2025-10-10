import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 9)
class UserSettings extends HiveObject {
  @HiveField(0)
  final String weightUnit; // e.g., "kg" or "lbs"

  UserSettings({required this.weightUnit});
}