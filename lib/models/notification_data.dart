/// Represents different types of notifications in the app
enum NotificationType {
  workoutReminder,
  restTimer,
  workoutComplete,
  motivational,
  general,
}

/// Data model for notification payload
class NotificationData {
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? payload;

  const NotificationData({
    required this.title,
    required this.body,
    required this.type,
    this.payload,
  });

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'type': type.name,
        'payload': payload,
      };

  /// Create from JSON
  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      NotificationData(
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NotificationType.general,
        ),
        payload: json['payload'] as Map<String, dynamic>?,
      );

  NotificationData copyWith({
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? payload,
  }) =>
      NotificationData(
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        payload: payload ?? this.payload,
      );
}

/// Settings for notification preferences
class NotificationSettings {
  final bool enabled;
  final bool workoutRemindersEnabled;
  final bool motivationalEnabled;
  final int workoutReminderHour; // 0-23 for hour of day
  final int workoutReminderMinute; // 0-59 for minute

  const NotificationSettings({
    this.enabled = true,
    this.workoutRemindersEnabled = true,
    this.motivationalEnabled = true,
    this.workoutReminderHour = 9, // Default 9 AM
    this.workoutReminderMinute = 0,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'workoutRemindersEnabled': workoutRemindersEnabled,
        'motivationalEnabled': motivationalEnabled,
        'workoutReminderHour': workoutReminderHour,
        'workoutReminderMinute': workoutReminderMinute,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        enabled: json['enabled'] as bool? ?? true,
        workoutRemindersEnabled:
            json['workoutRemindersEnabled'] as bool? ?? true,
        motivationalEnabled: json['motivationalEnabled'] as bool? ?? true,
        workoutReminderHour: json['workoutReminderHour'] as int? ?? 9,
        workoutReminderMinute: json['workoutReminderMinute'] as int? ?? 0,
      );

  NotificationSettings copyWith({
    bool? enabled,
    bool? workoutRemindersEnabled,
    bool? motivationalEnabled,
    int? workoutReminderHour,
    int? workoutReminderMinute,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        workoutRemindersEnabled:
            workoutRemindersEnabled ?? this.workoutRemindersEnabled,
        motivationalEnabled: motivationalEnabled ?? this.motivationalEnabled,
        workoutReminderHour: workoutReminderHour ?? this.workoutReminderHour,
        workoutReminderMinute:
            workoutReminderMinute ?? this.workoutReminderMinute,
      );
}
