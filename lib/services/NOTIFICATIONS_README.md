# GymPad Notification Service

A well-architected, easy-to-use local notifications system for the GymPad Flutter application.

## Architecture

The notification system follows GymPad's established architecture patterns:

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (Screens)                    │
│  - Settings screen to configure notifications           │
│  - Listen to notification taps for navigation           │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│              NotificationService (Singleton)             │
│  - Show instant notifications                           │
│  - Schedule future notifications                        │
│  - Manage notification channels                         │
│  - Handle platform-specific configuration               │
└───────────────────┬─────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼──────────┐  ┌────────▼─────────┐
│  NotificationData│  │ NotificationSettings│
│  (Domain Models) │  │   (Preferences)    │
└──────────────────┘  └────────┬───────────┘
                               │
                    ┌──────────▼──────────┐
                    │ NotificationSettings│
                    │    LSS (Hive)       │
                    └─────────────────────┘
```

## Components

### 1. Models (`lib/models/notification_data.dart`)

#### NotificationType
Enum defining different notification categories:
- `workoutReminder` - Daily workout reminders
- `restTimer` - Rest period notifications during workouts
- `workoutComplete` - Celebratory notification when workout is done
- `motivational` - Motivational messages
- `general` - General app notifications

#### NotificationData
Type-safe data model for notification content:
```dart
class NotificationData {
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? payload;
}
```

#### NotificationSettings
User preferences for notifications:
```dart
class NotificationSettings {
  final bool enabled;
  final bool workoutRemindersEnabled;
  final bool motivationalEnabled;
  final int workoutReminderHour;      // 0-23
  final int workoutReminderMinute;    // 0-59
}
```

### 2. Service (`lib/services/notification_service.dart`)

Singleton service following GymPad patterns:
- Factory constructor for single instance
- Uses `AppLogger` for consistent logging
- Lazy initialization with `initialize()` method
- Platform-specific configuration (Android/iOS)

Key methods:
- `initialize()` - Must be called once before use
- `showNotification()` - Display instant notification
- `scheduleNotification()` - Schedule for specific datetime
- `scheduleDailyNotification()` - Schedule recurring daily notification
- `cancelNotification()` - Cancel specific notification
- `cancelAllNotifications()` - Cancel all pending notifications
- `getSettings()` / `updateSettings()` - Manage user preferences

### 3. Local Storage (`lib/services/hive/notification_settings_lss.dart`)

Follows the LSS (Local Storage Service) pattern:
- Extends base `LSS<T, H>` class
- Type-safe domain ↔ Hive model conversion
- Consistent error handling and logging

### 4. Hive Adapter (`lib/services/hive/adapters/hive_notification_settings.dart`)

Type adapter for Hive storage:
- TypeId: 10 (ensure no conflicts with other adapters)
- Serializes `NotificationSettings` to Hive format
- Registered in `HiveInitializer`

## Setup & Installation

### 1. Dependencies

Already added to `pubspec.yaml`:
```yaml
dependencies:
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.4
```

### 2. Platform Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)
Permissions and receivers are configured:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

#### iOS (`ios/Runner/Info.plist`)
No changes needed - permissions requested at runtime.

### 3. Initialization

In `main.dart`, initialize the service early:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing initialization ...
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(const MyApp());
}
```

## Usage Examples

### Basic Notification

```dart
final notificationService = NotificationService();

await notificationService.showNotification(
  NotificationData(
    title: 'Workout Complete! 🎉',
    body: 'Great job! You completed your workout in 45 minutes',
    type: NotificationType.workoutComplete,
  ),
);
```

### Scheduled Notification

```dart
// Schedule a notification for tomorrow at 9 AM
final tomorrow = DateTime.now().add(Duration(days: 1));
final scheduledTime = DateTime(
  tomorrow.year,
  tomorrow.month,
  tomorrow.day,
  9, // hour
  0, // minute
);

await notificationService.scheduleNotification(
  id: 100,
  notification: NotificationData(
    title: 'Time to Workout!',
    body: 'Your body is ready for today\'s session',
    type: NotificationType.workoutReminder,
  ),
  scheduledTime: scheduledTime,
);
```

### Daily Recurring Notification

```dart
// Schedule daily workout reminder at 9:00 AM
await notificationService.scheduleDailyNotification(
  id: 1,
  notification: NotificationData(
    title: 'Daily Workout Reminder',
    body: 'Don\'t skip your workout today!',
    type: NotificationType.workoutReminder,
  ),
  hour: 9,
  minute: 0,
);
```

### With Custom Payload

```dart
await notificationService.showNotification(
  NotificationData(
    title: 'Rest Timer Complete',
    body: 'Time for your next set!',
    type: NotificationType.restTimer,
    payload: {
      'exerciseId': 'bench_press',
      'setNumber': 3,
      'workoutId': 'workout_123',
    },
  ),
);
```

### Managing Settings

```dart
// Get current settings
final settings = await notificationService.getSettings();

// Update settings
final newSettings = settings.copyWith(
  workoutRemindersEnabled: false,
  motivationalEnabled: true,
  workoutReminderHour: 18, // 6 PM
  workoutReminderMinute: 30,
);

await notificationService.updateSettings(newSettings);
```

### Handling Notification Taps

```dart
// Listen to notification tap events
notificationService.notificationTapStream.listen((notificationData) {
  // Navigate based on notification type or payload
  if (notificationData.type == NotificationType.workoutReminder) {
    router.go('/workouts');
  } else if (notificationData.payload != null) {
    final workoutId = notificationData.payload!['workoutId'];
    router.go('/workout/$workoutId');
  }
});
```

### Canceling Notifications

```dart
// Cancel specific notification
await notificationService.cancelNotification(100);

// Cancel all pending notifications
await notificationService.cancelAllNotifications();

// Get list of pending notifications
final pending = await notificationService.getPendingNotifications();
print('${pending.length} notifications pending');
```

## Integration with Workout Flow

### 1. Workout Complete Notification

```dart
// In WorkoutBloc when workout is completed
on<WorkoutCompleted>((event, emit) async {
  // ... existing logic ...
  
  // Show completion notification
  final duration = workout.endTime!.difference(workout.startTime);
  await NotificationService().showNotification(
    NotificationData(
      title: 'Workout Complete! 🎉',
      body: 'Finished in ${duration.inMinutes} minutes',
      type: NotificationType.workoutComplete,
    ),
  );
  
  emit(WorkoutComplete(workout: workout));
});
```

### 2. Rest Timer Notification

```dart
// During rest periods between sets
Future<void> scheduleRestTimerNotification(int seconds) async {
  final notificationService = NotificationService();
  
  await notificationService.scheduleNotification(
    id: 999, // Use fixed ID for rest timer
    notification: NotificationData(
      title: 'Rest Complete!',
      body: 'Time for your next set',
      type: NotificationType.restTimer,
    ),
    scheduledTime: DateTime.now().add(Duration(seconds: seconds)),
  );
}
```

### 3. Daily Workout Reminder

```dart
// In user settings or after questionnaire
Future<void> setupDailyReminder(int hour, int minute) async {
  final notificationService = NotificationService();
  
  await notificationService.scheduleDailyNotification(
    id: 1, // Use consistent ID for daily reminder
    notification: NotificationData(
      title: 'Time to Workout! 💪',
      body: 'Your body is ready for today\'s session',
      type: NotificationType.workoutReminder,
    ),
    hour: hour,
    minute: minute,
  );
}
```

## Notification Channels (Android)

Three channels are automatically created:

1. **Workout Channel** (High Priority)
   - Workout reminders, rest timers, completion notifications
   - Sound + vibration enabled
   - High importance for immediate attention

2. **General Channel** (Default Priority)
   - General app notifications
   - Sound enabled
   - Default importance

3. **Motivational Channel** (Low Priority)
   - Motivational messages
   - No sound or vibration
   - Low importance for non-disruptive messaging

## Testing

### Manual Testing Checklist

- [ ] Show instant notification
- [ ] Schedule future notification (1 minute ahead)
- [ ] Schedule daily notification
- [ ] Cancel specific notification
- [ ] Cancel all notifications
- [ ] Notification tap opens app
- [ ] Notification tap navigates correctly
- [ ] Settings persist after app restart
- [ ] Notifications survive device reboot (Android)
- [ ] iOS permission request appears
- [ ] Android notification channels appear in settings

### Test on Different Platforms

- [ ] Android (API 26+)
- [ ] iOS (13+)
- [ ] Test with notifications disabled in settings
- [ ] Test with app in background
- [ ] Test with app terminated

## Troubleshooting

### Notifications Not Appearing

1. Check if notifications are enabled:
```dart
final settings = await NotificationService().getSettings();
print('Notifications enabled: ${settings.enabled}');
```

2. Check platform permissions:
   - Android: Settings → Apps → GymPad → Notifications
   - iOS: Settings → GymPad → Notifications

3. Check initialization:
```dart
final service = NotificationService();
print('Service initialized: ${service.isInitialized}');
```

### Scheduled Notifications Not Firing

1. Verify timezone is initialized:
```dart
import 'package:timezone/timezone.dart' as tz;
tz.initializeTimeZones();
```

2. Check pending notifications:
```dart
final pending = await notificationService.getPendingNotifications();
pending.forEach((req) {
  print('Pending: ${req.id} - ${req.title}');
});
```

3. Android: Ensure SCHEDULE_EXACT_ALARM permission is granted

### iOS Notifications Not Appearing

1. Check permission status in iOS Settings
2. Verify Info.plist doesn't have restrictive settings
3. Test on physical device (simulator may have issues)

## Best Practices

1. **Use Consistent IDs**: Use fixed IDs for recurring notifications (e.g., daily reminders)
2. **Cancel Old Notifications**: Cancel previous notifications before scheduling new ones
3. **Check Settings**: Always check if notification type is enabled before showing
4. **Handle Payload**: Use structured payloads for complex navigation
5. **Test on Devices**: Always test on physical devices, not just simulators
6. **Log Everything**: Use AppLogger for debugging notification issues
7. **Graceful Degradation**: App should work fine if notifications fail

## Future Enhancements

Possible additions:
- Action buttons on notifications (e.g., "Start Workout", "Snooze")
- Notification history/inbox
- Rich notifications with images
- Custom notification sounds
- Notification grouping/categories
- Analytics for notification engagement
- Smart scheduling based on user patterns

## References

- [flutter_local_notifications documentation](https://pub.dev/packages/flutter_local_notifications)
- [Android notification channels](https://developer.android.com/develop/ui/views/notifications/channels)
- [iOS notification permissions](https://developer.apple.com/documentation/usernotifications)
- GymPad AGENTS.md for architecture patterns
