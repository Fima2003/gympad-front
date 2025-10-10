import '../../models/withAdapters/user_settings.dart';
import 'lss.dart';

class UserSettingsLss extends LSS<UserSettings, UserSettings> {
  static const String _boxName = 'user_settings_box';
  static const String _defaultKey = 'user_settings';

  UserSettingsLss() : super(_boxName, defaultKey: _defaultKey);

  @override
  UserSettings fromDomain(UserSettings domain) => domain;

  @override
  UserSettings toDomain(UserSettings hive) => hive;

  @override
  String getKey(UserSettings domain) => _defaultKey;
}
