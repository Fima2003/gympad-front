import 'package:hive/hive.dart';
import '../../../models/notification_data.dart';

part 'hive_notification_settings.g.dart';

/// Hive adapter for storing notification settings
@HiveType(typeId: 10)
class HiveNotificationSettings extends HiveObject {
  @HiveField(0)
  final bool enabled;
  @HiveField(1)
  final bool workoutRemindersEnabled;
  @HiveField(2)
  final bool motivationalEnabled;
  @HiveField(3)
  final int workoutReminderHour;
  @HiveField(4)
  final int workoutReminderMinute;

  HiveNotificationSettings({
    required this.enabled,
    required this.workoutRemindersEnabled,
    required this.motivationalEnabled,
    required this.workoutReminderHour,
    required this.workoutReminderMinute,
  });

  factory HiveNotificationSettings.fromDomain(NotificationSettings settings) =>
      HiveNotificationSettings(
        enabled: settings.enabled,
        workoutRemindersEnabled: settings.workoutRemindersEnabled,
        motivationalEnabled: settings.motivationalEnabled,
        workoutReminderHour: settings.workoutReminderHour,
        workoutReminderMinute: settings.workoutReminderMinute,
      );

  NotificationSettings toDomain() => NotificationSettings(
        enabled: enabled,
        workoutRemindersEnabled: workoutRemindersEnabled,
        motivationalEnabled: motivationalEnabled,
        workoutReminderHour: workoutReminderHour,
        workoutReminderMinute: workoutReminderMinute,
      );
}
