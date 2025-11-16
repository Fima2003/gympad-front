# Quick Start Guide - GymPad Notifications

**5-minute guide to start using notifications in GymPad**

## Setup (One-time)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Verify Initialization
The notification service is already initialized in `main.dart`. ✅

## Basic Usage

### Show Instant Notification
```dart
import 'package:gympad/services/notification_helper.dart';
import 'package:gympad/models/notification_data.dart';

// Show workout completion
await NotificationHelper.showWorkoutCompleteNotification(workout);

// Or create custom notification
await NotificationService().showNotification(
  NotificationData(
    title: 'Custom Title',
    body: 'Custom message',
    type: NotificationType.general,
  ),
);
```

### Schedule Rest Timer
```dart
// Schedule 60-second rest timer
await NotificationHelper.scheduleRestTimerNotification(
  restSeconds: 60,
  exerciseName: 'Bench Press',
  setNumber: 2,
);
```

### Setup Daily Reminder
```dart
// Setup daily workout reminder at 9:00 AM
await NotificationHelper.setupDailyWorkoutReminder(
  hour: 9,
  minute: 0,
);
```

## Integration Examples

### In WorkoutBloc
```dart
import '../../services/notification_helper.dart';

// In workout completion handler
on<WorkoutCompleted>((event, emit) async {
  // ... save workout logic ...
  
  // Show notification
  await NotificationHelper.showWorkoutCompleteNotification(event.workout);
  
  emit(WorkoutComplete(workout: event.workout));
});
```

### In Settings Screen
```dart
import '../settings/notification_settings_screen.dart';

// Add to settings list
ListTile(
  leading: Icon(Icons.notifications),
  title: Text('Notifications'),
  subtitle: Text('Manage notification preferences'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NotificationSettingsScreen(),
    ),
  ),
)
```

### After Questionnaire
```dart
import '../../services/notification_helper.dart';

Future<void> _completeQuestionnaire() async {
  // ... save questionnaire ...
  
  // Setup daily reminder
  await NotificationHelper.setupDailyWorkoutReminder(
    hour: 9,  // User's preferred time
    minute: 0,
  );
  
  // Navigate next
  context.go('/main');
}
```

## Available Notification Types

| Type | Use Case | Priority |
|------|----------|----------|
| `workoutReminder` | Daily workout reminders | High |
| `restTimer` | Rest period complete | Max |
| `workoutComplete` | Workout finished | High |
| `motivational` | Inspiration messages | Low |
| `general` | App updates | Default |

## Available Helper Functions

```dart
// Workout-related
NotificationHelper.showWorkoutCompleteNotification(workout)
NotificationHelper.scheduleRestTimerNotification(restSeconds, exerciseName, setNumber)
NotificationHelper.cancelRestTimer()

// Daily reminders
NotificationHelper.setupDailyWorkoutReminder(hour, minute)
NotificationHelper.cancelDailyWorkoutReminder()

// Motivational
NotificationHelper.showMotivationalNotification(title, message)
NotificationHelper.showRandomMotivationalNotification()

// Milestones
NotificationHelper.showMilestoneNotification(milestone, message)

// Scheduled workouts
NotificationHelper.scheduleWorkoutReminder(scheduledTime, workoutName, [id])
```

## Testing Notifications

### Manual Test (Development)
Add test button in debug mode:
```dart
if (kDebugMode)
  ElevatedButton(
    child: Text('Test Notification'),
    onPressed: () async {
      await NotificationService().showNotification(
        NotificationData(
          title: 'Test Notification',
          body: 'This is a test',
          type: NotificationType.general,
        ),
      );
    },
  )
```

### Use Settings Screen
Navigate to Notification Settings screen and use the test buttons.

## Common Patterns

### Cancel Old Notification Before Scheduling New One
```dart
// Cancel previous rest timer
await NotificationService().cancelNotification(999);

// Schedule new rest timer
await NotificationHelper.scheduleRestTimerNotification(
  restSeconds: 90,
  exerciseName: 'Squats',
  setNumber: 1,
);
```

### Check if Notifications Enabled
```dart
final settings = await NotificationService().getSettings();
if (settings.enabled && settings.workoutRemindersEnabled) {
  // Show workout reminder
}
```

### Milestone Notification Example
```dart
final totalWorkouts = await _getWorkoutCount();
if (totalWorkouts == 10) {
  await NotificationHelper.showMilestoneNotification(
    milestone: '10 Workouts!',
    message: 'You\'ve completed 10 workouts. Keep it up!',
  );
}
```

## Notification IDs

Use consistent IDs for recurring notifications:
- `1` - Daily workout reminder
- `999` - Rest timer
- `workoutId.hashCode` - Scheduled workout reminders
- Auto-generated - One-time notifications

## Troubleshooting

### Notifications Not Appearing
1. Check if enabled in settings:
   ```dart
   final settings = await NotificationService().getSettings();
   print('Enabled: ${settings.enabled}');
   ```
2. Check device notification permissions
3. Test on real device (not simulator)

### Scheduled Notifications Not Firing
1. Verify time is in the future
2. Check pending notifications:
   ```dart
   final pending = await NotificationService().getPendingNotifications();
   print('Pending: ${pending.length}');
   ```
3. On Android, check battery optimization settings

## Full Documentation

For complete documentation, see:
- **NOTIFICATIONS_README.md** - Full API documentation
- **NOTIFICATION_USAGE_EXAMPLES.md** - Detailed integration examples
- **NOTIFICATION_SYSTEM_SUMMARY.md** - Implementation overview

## API Quick Reference

### NotificationService
```dart
// Singleton instance
final service = NotificationService();

// Methods
await service.initialize()
await service.showNotification(notificationData)
await service.scheduleNotification(id, notification, scheduledTime)
await service.scheduleDailyNotification(id, notification, hour, minute)
await service.cancelNotification(id)
await service.cancelAllNotifications()
final settings = await service.getSettings()
await service.updateSettings(newSettings)
final pending = await service.getPendingNotifications()

// Stream
service.notificationTapStream.listen((data) { /* handle tap */ })
```

### NotificationData
```dart
NotificationData(
  title: 'Title',
  body: 'Body text',
  type: NotificationType.general,
  payload: {'key': 'value'},  // Optional
)
```

### NotificationSettings
```dart
NotificationSettings(
  enabled: true,
  workoutRemindersEnabled: true,
  motivationalEnabled: true,
  workoutReminderHour: 9,
  workoutReminderMinute: 0,
)
```

---

**That's it!** You're ready to use notifications in GymPad. Start with the helper functions for common patterns, and refer to the full documentation for advanced usage.
