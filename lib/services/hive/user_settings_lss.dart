import '../../models/user_settings.dart';
import 'adapters/hive_user_settings.dart';
import 'lss.dart';

class UserSettingsLss extends LSS<UserSettings, HiveUserSettings> {
  static const String _boxName = 'user_settings_box';
  static const String _defaultKey = 'user_settings';

  UserSettingsLss() : super(_boxName, defaultKey: _defaultKey);

  @override
  HiveUserSettings fromDomain(UserSettings domain) =>
      HiveUserSettings.fromDomain(domain);

  @override
  UserSettings toDomain(HiveUserSettings hive) => hive.toDomain();

  @override
  String getKey(UserSettings domain) => _defaultKey;
}
