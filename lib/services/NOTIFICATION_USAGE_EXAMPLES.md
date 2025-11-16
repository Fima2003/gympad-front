# Notification Service Usage Examples

This document provides concrete examples of integrating the notification service into GymPad's existing workflow.

## Table of Contents
1. [Integration with WorkoutBloc](#integration-with-workoutbloc)
2. [Integration with Settings](#integration-with-settings)
3. [Rest Timer Integration](#rest-timer-integration)
4. [Startup Configuration](#startup-configuration)
5. [Handling Notification Taps](#handling-notification-taps)

---

## Integration with WorkoutBloc

### Showing Workout Completion Notification

```dart
// In lib/blocs/workout/workout_bloc.dart

import '../../services/notification_helper.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  // ... existing code ...

  WorkoutBloc() : super(WorkoutInitial()) {
    on<WorkoutCompleted>(_onWorkoutCompleted);
    // ... other handlers ...
  }

  Future<void> _onWorkoutCompleted(
    WorkoutCompleted event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      final workout = event.workout;
      
      // Mark workout as completed
      workout.endTime = DateTime.now();
      
      // Save to storage/API
      await _workoutService.saveWorkout(workout);
      
      // Show completion notification
      await NotificationHelper.showWorkoutCompleteNotification(workout);
      
      emit(WorkoutComplete(workout: workout));
    } catch (e, st) {
      _logger.severe('Failed to complete workout', e, st);
      emit(WorkoutError(message: 'Failed to complete workout'));
    }
  }
}
```

---

## Integration with Settings

### Adding Notification Settings to Settings Screen

```dart
// In lib/screens/settings/settings.dart

import '../../services/notification_service.dart';
import '../settings/notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // ... existing settings items ...
          
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          
          // ... more settings items ...
        ],
      ),
    );
  }
}
```

### Quick Toggle for Notifications

```dart
// Add a quick toggle switch in settings
class _NotificationQuickToggle extends StatefulWidget {
  const _NotificationQuickToggle();

  @override
  State<_NotificationQuickToggle> createState() =>
      _NotificationQuickToggleState();
}

class _NotificationQuickToggleState extends State<_NotificationQuickToggle> {
  final _notificationService = NotificationService();
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _notificationService.getSettings();
    setState(() => _enabled = settings.enabled);
  }

  Future<void> _toggleNotifications(bool value) async {
    final settings = await _notificationService.getSettings();
    await _notificationService.updateSettings(
      settings.copyWith(enabled: value),
    );
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Enable Notifications'),
      subtitle: const Text('Receive workout reminders and updates'),
      value: _enabled,
      onChanged: _toggleNotifications,
    );
  }
}
```

---

## Rest Timer Integration

### Scheduling Rest Timer During Workout

```dart
// In your workout screen or timer widget
import '../../services/notification_helper.dart';

class WorkoutRestTimer extends StatefulWidget {
  final int restSeconds;
  final String exerciseName;
  final int setNumber;

  const WorkoutRestTimer({
    super.key,
    required this.restSeconds,
    required this.exerciseName,
    required this.setNumber,
  });

  @override
  State<WorkoutRestTimer> createState() => _WorkoutRestTimerState();
}

class _WorkoutRestTimerState extends State<WorkoutRestTimer> {
  @override
  void initState() {
    super.initState();
    _startRestTimer();
  }

  Future<void> _startRestTimer() async {
    await NotificationHelper.scheduleRestTimerNotification(
      restSeconds: widget.restSeconds,
      exerciseName: widget.exerciseName,
      setNumber: widget.setNumber + 1, // Next set
    );
  }

  @override
  void dispose() {
    // Cancel notification if user manually ends rest early
    NotificationHelper.cancelRestTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Your rest timer UI
    return Container(
      // ... timer UI ...
    );
  }
}
```

### Rest Timer with Auto-Complete

```dart
// In lib/blocs/workout/workout_bloc.dart

on<SetCompleted>((event, emit) async {
  final currentState = state;
  if (currentState is! WorkoutInProgress) return;

  // Get rest time for this exercise
  final restTime = _getRestTimeForExercise(event.exerciseId);
  
  if (restTime > 0) {
    // Schedule rest timer notification
    await NotificationHelper.scheduleRestTimerNotification(
      restSeconds: restTime,
      exerciseName: event.exerciseName,
      setNumber: event.setNumber,
    );
  }
  
  // ... rest of the handler ...
});
```

---

## Startup Configuration

### Setting Up Daily Reminders After Questionnaire

```dart
// In lib/screens/questionnaire/questionnaire_screen.dart

import '../../services/notification_helper.dart';

class QuestionnaireScreen extends StatefulWidget {
  // ... existing code ...
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  // ... existing code ...

  Future<void> _submitQuestionnaire() async {
    try {
      // ... save questionnaire data ...
      
      // Setup daily workout reminder based on user's preferred time
      final preferredWorkoutHour = _getPreferredWorkoutHour();
      await NotificationHelper.setupDailyWorkoutReminder(
        hour: preferredWorkoutHour,
        minute: 0,
      );
      
      // Navigate to next screen
      if (mounted) {
        context.go('/main');
      }
    } catch (e, st) {
      _logger.severe('Failed to submit questionnaire', e, st);
    }
  }
  
  int _getPreferredWorkoutHour() {
    // Based on user's answer about preferred workout time
    // Morning: 9, Afternoon: 14, Evening: 18
    return 9; // Default to morning
  }
}
```

### Initialize Notification Listener in Main App

```dart
// In lib/main.dart

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  StreamSubscription<NotificationData>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeRouter();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    // Listen to notification taps
    _notificationSubscription = NotificationService()
        .notificationTapStream
        .listen(_handleNotificationTap);
  }

  void _handleNotificationTap(NotificationData data) {
    // Handle navigation based on notification type
    switch (data.type) {
      case NotificationType.workoutReminder:
        _router.go('/workouts');
        break;
      case NotificationType.workoutComplete:
        if (data.payload?['workoutId'] != null) {
          _router.go('/workout/${data.payload!['workoutId']}');
        }
        break;
      case NotificationType.restTimer:
        // Return to active workout
        _router.go('/workout/active');
        break;
      default:
        _router.go('/main');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // ... rest of the widget ...
}
```

---

## Handling Notification Taps

### Advanced Navigation with Payload

```dart
import 'dart:convert';
import '../../models/notification_data.dart';
import '../../services/notification_service.dart';

class NotificationRouter {
  final GoRouter router;

  NotificationRouter(this.router);

  void initialize() {
    NotificationService().notificationTapStream.listen(_handleNotification);
  }

  void _handleNotification(NotificationData data) {
    switch (data.type) {
      case NotificationType.workoutReminder:
        _handleWorkoutReminder(data);
        break;
      case NotificationType.workoutComplete:
        _handleWorkoutComplete(data);
        break;
      case NotificationType.restTimer:
        _handleRestTimer(data);
        break;
      case NotificationType.motivational:
        _handleMotivational(data);
        break;
      case NotificationType.general:
        _handleGeneral(data);
        break;
    }
  }

  void _handleWorkoutReminder(NotificationData data) {
    // Navigate to workouts list
    router.go('/workouts');
  }

  void _handleWorkoutComplete(NotificationData data) {
    final workoutId = data.payload?['workoutId'];
    if (workoutId != null) {
      // Navigate to workout detail/summary
      router.go('/workout/summary/$workoutId');
    } else {
      router.go('/main');
    }
  }

  void _handleRestTimer(NotificationData data) {
    // Return to active workout session
    router.go('/workout/active');
  }

  void _handleMotivational(NotificationData data) {
    // Just go to main screen
    router.go('/main');
  }

  void _handleGeneral(NotificationData data) {
    // Check if there's a specific destination in payload
    final destination = data.payload?['destination'];
    if (destination != null) {
      router.go(destination);
    } else {
      router.go('/main');
    }
  }
}

// Usage in main.dart:
// final notificationRouter = NotificationRouter(_router);
// notificationRouter.initialize();
```

---

## Milestone Notifications

### Tracking and Celebrating Milestones

```dart
// In a service or bloc that tracks workout history
import '../../services/notification_helper.dart';

class WorkoutHistoryService {
  // ... existing code ...

  Future<void> checkAndShowMilestones(int totalWorkouts) async {
    // Check for milestone achievements
    if (totalWorkouts == 1) {
      await NotificationHelper.showMilestoneNotification(
        milestone: 'First Workout!',
        message: 'You\'ve completed your first workout. Great start!',
      );
    } else if (totalWorkouts == 10) {
      await NotificationHelper.showMilestoneNotification(
        milestone: '10 Workouts!',
        message: 'You\'ve completed 10 workouts. Keep it up!',
      );
    } else if (totalWorkouts == 50) {
      await NotificationHelper.showMilestoneNotification(
        milestone: '50 Workouts!',
        message: 'Half century of workouts! You\'re on fire! 🔥',
      );
    } else if (totalWorkouts == 100) {
      await NotificationHelper.showMilestoneNotification(
        milestone: '100 Workouts!',
        message: 'Century club! You\'re a fitness champion! 🏆',
      );
    }
  }
}
```

---

## Scheduled Workout Reminders

### For Personal Workout Programs

```dart
// When user schedules a personal workout
import '../../services/notification_helper.dart';

class PersonalWorkoutBloc extends Bloc<PersonalWorkoutEvent, PersonalWorkoutState> {
  // ... existing code ...

  on<SchedulePersonalWorkout>((event, emit) async {
    final workout = event.workout;
    final scheduledTime = event.scheduledTime;

    // Save workout schedule
    await _personalWorkoutService.scheduleWorkout(workout, scheduledTime);

    // Schedule notification 15 minutes before
    final reminderTime = scheduledTime.subtract(const Duration(minutes: 15));
    if (reminderTime.isAfter(DateTime.now())) {
      await NotificationHelper.scheduleWorkoutReminder(
        scheduledTime: reminderTime,
        workoutName: workout.name,
        notificationId: workout.id.hashCode,
      );
    }

    emit(PersonalWorkoutScheduled(workout: workout));
  });
}
```

---

## Weekly Motivation

### Send Weekly Motivational Message

```dart
// In a background task or scheduled job
import '../../services/notification_helper.dart';

class WeeklyMotivationTask {
  static Future<void> scheduleWeeklyMotivation() async {
    // Schedule for every Sunday at 8 PM
    final now = DateTime.now();
    var nextSunday = now.add(Duration(days: (7 - now.weekday) % 7));
    nextSunday = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      20, // 8 PM
      0,
    );

    if (nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }

    final notificationService = NotificationService();
    await notificationService.scheduleNotification(
      id: 7777, // Fixed ID for weekly motivation
      notification: NotificationData(
        title: 'Week Ahead! 🎯',
        body: 'Plan your workouts for the week and crush your goals!',
        type: NotificationType.motivational,
      ),
      scheduledTime: nextSunday,
    );
  }
}
```

---

## Testing in Development

### Quick Test Button in Debug Mode

```dart
// In lib/screens/settings/settings.dart (only in debug mode)

import 'package:flutter/foundation.dart';
import '../../services/notification_helper.dart';

class SettingsScreen extends StatelessWidget {
  // ... existing code ...

  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // ... existing settings ...
          
          if (kDebugMode) ...[
            const Divider(),
            ListTile(
              title: const Text('Test Notifications (Debug Only)'),
              subtitle: const Text('Quick test for development'),
              trailing: const Icon(Icons.bug_report),
              onTap: () => _showTestDialog(context),
            ),
          ],
        ],
      ),
    );
  }

  void _showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await NotificationHelper.showRandomMotivationalNotification();
                Navigator.pop(context);
              },
              child: const Text('Test Motivational'),
            ),
            ElevatedButton(
              onPressed: () async {
                await NotificationHelper.scheduleRestTimerNotification(
                  restSeconds: 5,
                  exerciseName: 'Test Exercise',
                  setNumber: 1,
                );
                Navigator.pop(context);
              },
              child: const Text('Test Rest Timer (5s)'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Best Practices Summary

1. **Always check if notifications are enabled** before showing/scheduling
2. **Use consistent IDs** for recurring notifications (daily reminders, rest timers)
3. **Cancel old notifications** before scheduling new ones with the same ID
4. **Handle errors gracefully** - app should work even if notifications fail
5. **Test on real devices** - simulator behavior can differ
6. **Use NotificationHelper** for common patterns to keep code DRY
7. **Log all notification actions** for debugging
8. **Respect user preferences** from NotificationSettings
9. **Use appropriate notification types** for correct channel/priority
10. **Include useful payloads** for navigation on tap
