# Workout Notification System - Architecture

## Overview
This document describes the architecture and implementation details of the workout notification system.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                          │
│                                                          │
│  ┌────────────────────────────────────────────────┐     │
│  │              main.dart (_MyAppState)           │     │
│  │                                                │     │
│  │  - Initializes NotificationsHandler           │     │
│  │  - Provides BLoC instances                    │     │
│  │  - Manages lifecycle                          │     │
│  └────────────────────────────────────────────────┘     │
│                          │                               │
│                          │ initialize()                  │
│                          ▼                               │
│  ┌────────────────────────────────────────────────┐     │
│  │        NotificationsHandler                    │     │
│  │    (notifications_handler.dart)                │     │
│  │                                                │     │
│  │  WidgetsBindingObserver mixin:                │     │
│  │  - didChangeAppLifecycleState()               │     │
│  │                                                │     │
│  │  State Management:                             │     │
│  │  - Listens to WorkoutBloc.stream              │     │
│  │  - Tracks app foreground/background           │     │
│  │  - Manages notification timer                 │     │
│  │                                                │     │
│  │  Logic:                                        │     │
│  │  - Shows notification on background           │     │
│  │  - Hides notification on foreground           │     │
│  │  - Routes actions to WorkoutBloc              │     │
│  └────────────────────────────────────────────────┘     │
│           │                          │                   │
│           │ showBreakNotification()  │                   │
│           │ showSetNotification()    │                   │
│           │                          │                   │
│           ▼                          │                   │
│  ┌────────────────────────────┐     │                   │
│  │   NotificationService      │     │                   │
│  │ (notification_service.dart)│     │                   │
│  │                            │     │                   │
│  │  Singleton Service:        │     │                   │
│  │  - FlutterLocal            │     │                   │
│  │    Notifications           │     │                   │
│  │  - Channels (Android)      │     │                   │
│  │  - Permissions (iOS)       │     │                   │
│  │  - Action handling         │     │                   │
│  └────────────────────────────┘     │                   │
│                                      │                   │
│  Workout State Flow                  │                   │
│  ┌────────────────────────────┐     │                   │
│  │       WorkoutBloc          │◄────┘                   │
│  │                            │  add(event)             │
│  │  States:                   │                         │
│  │  - WorkoutRunRest          │                         │
│  │  - WorkoutRunInSet         │                         │
│  │                            │                         │
│  │  Events:                   │                         │
│  │  - RunExtendRest           │                         │
│  │  - RunSkipRest             │                         │
│  └────────────────────────────┘                         │
└─────────────────────────────────────────────────────────┘
```

## Component Responsibilities

### 1. NotificationService (`lib/services/notification_service.dart`)

**Purpose**: Low-level service for displaying and managing notifications.

**Key Responsibilities**:
- Initialize flutter_local_notifications plugin
- Create notification channels (Android)
- Request permissions (iOS)
- Show/update/cancel notifications
- Handle notification taps and action taps

**Key Methods**:
```dart
Future<void> initialize()
Future<void> showBreakNotification({...})
Future<void> showSetNotification({...})
Future<void> updateBreakNotification({...})
Future<void> updateSetNotification({...})
Future<void> cancelBreakNotification()
Future<void> cancelSetNotification()
Future<void> cancelAllNotifications()
```

**Callbacks**:
- `onNotificationTapped`: Called when notification body is tapped
- `onActionTapped`: Called when action button is tapped

**Notification IDs**:
- Break: 100
- Set: 101

**Channel IDs** (Android):
- Break: `workout_break`
- Set: `workout_set`

**Action IDs**:
- `add_30s`: Add 30 seconds to rest
- `skip_break`: Skip rest period
- `finish_set`: Finish current set

### 2. NotificationsHandler (`lib/notifications/notifications_handler.dart`)

**Purpose**: High-level integration layer between app lifecycle, workout state, and notifications.

**Key Responsibilities**:
- Monitor app lifecycle state (foreground/background)
- Listen to workout state changes from WorkoutBloc
- Decide when to show/hide notifications
- Update notifications with current workout data
- Route notification actions to WorkoutBloc
- Manage periodic timer for notification updates

**Lifecycle Management**:
```dart
// App goes to background
didChangeAppLifecycleState(AppLifecycleState.paused)
  → _isInBackground = true
  → _showNotificationIfNeeded()
  → _startNotificationUpdateTimer()

// App comes to foreground
didChangeAppLifecycleState(AppLifecycleState.resumed)
  → _isInBackground = false
  → _stopNotificationUpdateTimer()
  → cancelAllNotifications()
```

**State-to-Notification Mapping**:
```dart
WorkoutRunRest → Break Notification
  - Timer counts down (remaining)
  - Shows next exercise
  - Actions: +30s, Skip

WorkoutRunInSet → Set Notification
  - Timer counts up (elapsed)
  - Shows current exercise
  - Action: Finish (context-dependent text)

Other states → No notification (cancel all)
```

**Update Timer**:
- Runs every 1 second when app is in background
- Updates notification with current time
- Automatically stopped when app returns to foreground

### 3. Main App Integration (`lib/main.dart`)

**Initialization Flow**:
```dart
1. _MyAppState created
2. MultiBlocProvider creates all blocs
3. Builder widget accesses blocs via context
4. NotificationsHandler.initialize() called once
5. Handler registers as WidgetsBindingObserver
6. Handler subscribes to WorkoutBloc.stream
```

**Cleanup**:
```dart
_MyAppState.dispose()
  → NotificationsHandler.dispose()
    → Cancel subscriptions
    → Stop timers
    → Remove lifecycle observer
    → Cancel all notifications
```

## Data Flow

### Break Notification Flow

```
User completes set
  → WorkoutBloc emits WorkoutRunRest
  → NotificationsHandler._onWorkoutStateChanged()
  → if (_isInBackground) _showNotificationIfNeeded()
  → _showBreakNotification(WorkoutRunRest state)
    - Extract next exercise from state
    - Get exercise name from DataBloc
    - Get weight with unit from UserSettingsBloc
    - Call NotificationService.showBreakNotification()
  → Timer updates notification every second
```

### Set Notification Flow

```
User starts set
  → WorkoutBloc emits WorkoutRunInSet
  → NotificationsHandler._onWorkoutStateChanged()
  → if (_isInBackground) _showNotificationIfNeeded()
  → _showSetNotification(WorkoutRunInSet state)
    - Extract current exercise from state
    - Get exercise name from DataBloc
    - Determine finish button text from finishType
    - Call NotificationService.showSetNotification()
  → Timer updates notification every second
```

### Action Handling Flow

```
User taps +30s button
  → Android/iOS system captures tap
  → NotificationService._onNotificationResponse()
  → onActionTapped?.call('add_30s')
  → NotificationsHandler._handleActionTap('add_30s')
  → WorkoutBloc.add(RunExtendRest(seconds: 30))
  → WorkoutBloc updates rest remaining
  → New state emitted
  → Notification updated with new time
```

## State Machine

```
┌─────────────────┐
│  App Foreground │
│  No Notification│
└────────┬────────┘
         │
         │ User presses home during workout
         │
         ▼
    ┌────────────────────┐
    │  App Background    │
    │                    │
    │  ┌──────────────┐  │
    │  │WorkoutRunRest│  │
    │  │    Active    │  │
    │  └──────┬───────┘  │
    │         │          │
    │         │ Show break notification
    │         │ Start update timer
    │         │
    │         ▼          │
    │  Break Notification│
    │  Displayed         │
    └────────┬───────────┘
             │
             │ Action: +30s
             │
             ▼
    ┌────────────────────┐
    │  Bloc processes    │
    │  RunExtendRest     │
    └────────┬───────────┘
             │
             │ State updated
             │
             ▼
    ┌────────────────────┐
    │ Notification       │
    │ Updated with       │
    │ new time           │
    └────────────────────┘
```

## Threading Model

### Main Thread
- NotificationsHandler runs on main thread
- Listens to WorkoutBloc stream
- Receives app lifecycle events
- Calls NotificationService methods

### Background Isolate (Android/iOS)
- `_onBackgroundNotificationResponse()` marked with `@pragma('vm:entry-point')`
- Runs in separate isolate when app is terminated
- Limited functionality (no access to main app state)
- Currently just returns immediately

### Timer Thread
- `Timer.periodic()` runs on main thread
- Updates notification every second
- Lightweight operation (just calls show method again)

## Platform Differences

### Android
- **Notification Channels**: Required on Android 8.0+
  - Break channel: High importance, vibration enabled
  - Set channel: High importance, vibration enabled
- **Action Buttons**: Full support, shows all actions
- **Colors**: Uses `color` and `colorized` properties
- **Ongoing**: Notifications set as ongoing (can't be dismissed by swipe)
- **Permissions**: Required on Android 13+ (requested automatically)

### iOS
- **Notification Channels**: Not applicable
- **Action Buttons**: Limited support, may show differently
- **Colors**: Limited support for colored notifications
- **Ongoing**: Not supported (all notifications dismissible)
- **Permissions**: Requested via `requestPermissions()`

## Performance Considerations

### Battery Impact
- **Update Frequency**: 1 second is reasonable for background timer
- **Optimization**: Only updates when in background
- **Cleanup**: Timer stopped immediately on foreground

### Memory
- **Singleton Pattern**: NotificationService uses singleton
- **Weak References**: Handler doesn't hold strong references to blocs
- **Cleanup**: All resources cleaned up in dispose()

### Network
- **No Network Calls**: All data from local blocs
- **No Remote Notifications**: Pure local notifications

## Error Handling

### Initialization Failures
```dart
try {
  await _notifications.initialize(...)
} catch (e, st) {
  _logger.error('Failed to initialize', e, st)
  // App continues without notifications
}
```

### Show Failures
```dart
if (!_isInitialized) {
  _logger.warning('Not initialized')
  return // Silently fail
}
try {
  await _notifications.show(...)
} catch (e, st) {
  _logger.error('Failed to show', e, st)
  // Notification not shown, but app continues
}
```

### Null Safety
- All nullable fields checked before use
- Default values provided where appropriate
- Graceful degradation if data unavailable

## Testing Strategy

### Unit Tests (Recommended)
- `NotificationService`: Test all public methods with mocked plugin
- `NotificationsHandler`: Test state-to-notification mapping
- Action handling: Test event dispatching

### Integration Tests (Recommended)
- Full lifecycle: Foreground → Background → Foreground
- Action tap flows: Button → Event → State → Notification
- State transitions during background

### Manual Tests (Required)
- Physical device testing
- Notification appearance verification
- Action button functionality
- Timer accuracy
- Platform-specific behavior

## Debugging

### Enable Logging
All components use `AppLogger`:
```dart
_logger.info('Notification displayed')
_logger.warning('Service not initialized')
_logger.error('Failed to show notification', error, stackTrace)
```

### Check Logs
```bash
# Android
adb logcat | grep -i notification

# iOS
# Use Xcode console
```

### Common Issues
1. **Notifications not appearing**: Check permissions
2. **Timer not updating**: Check lifecycle events
3. **Actions not working**: Check action IDs match
4. **Wrong data shown**: Check bloc state inspection

## Future Improvements

### Short Term
1. Add workout progress percentage to notification
2. Support for custom notification sounds
3. Add haptic feedback on action taps

### Medium Term
1. Rich notification with workout statistics
2. Quick reply for custom reps/weight
3. Notification history/stacking

### Long Term
1. Wear OS companion notifications
2. Smart watch integration
3. Predictive notifications (upcoming exercise)
4. Social features (notify workout buddy)

## Dependencies

### Required Packages
- `flutter_local_notifications: ^19.5.0`
- `flutter_bloc: ^9.1.1`

### Platform Requirements
- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 10.0+

### Permissions
- Android: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`
- iOS: Notification permissions (requested at runtime)

## References

### Documentation
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [Android Notification Guidelines](https://developer.android.com/design/patterns/notifications)
- [iOS Notification Guidelines](https://developer.apple.com/design/human-interface-guidelines/notifications)

### Related Files
- `lib/blocs/workout/workout_bloc.dart` - Workout state management
- `lib/blocs/workout/workout_state.dart` - State definitions
- `lib/blocs/workout/workout_events.dart` - Event definitions
- `lib/screens/workouts/.../cworkout_break_view.dart` - Break screen
- `lib/screens/workouts/.../cworkout_set_view.dart` - Set screen
