import '../../models/notification_data.dart';
import 'adapters/hive_notification_settings.dart';
import 'lss.dart';

/// Local storage service for notification settings
class NotificationSettingsLss
    extends LSS<NotificationSettings, HiveNotificationSettings> {
  static const String _boxName = 'notification_settings_box';
  static const String _defaultKey = 'notification_settings';

  NotificationSettingsLss() : super(_boxName, defaultKey: _defaultKey);

  @override
  HiveNotificationSettings fromDomain(NotificationSettings domain) =>
      HiveNotificationSettings.fromDomain(domain);

  @override
  NotificationSettings toDomain(HiveNotificationSettings hive) =>
      hive.toDomain();

  @override
  String getKey(NotificationSettings domain) => _defaultKey;
}
