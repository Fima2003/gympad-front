import '../models/notification_data.dart';
import '../models/workout.dart';
import 'logger_service.dart';
import 'notification_service.dart';

/// Helper functions for common notification patterns in the app.
///
/// This demonstrates how to integrate NotificationService into
/// various parts of the application workflow.
class NotificationHelper {
  static final _notificationService = NotificationService();
  static final _logger = AppLogger().createLogger('NotificationHelper');

  /// Show workout completion notification with workout details
  static Future<void> showWorkoutCompleteNotification(Workout workout) async {
    try {
      final duration = workout.endTime != null
          ? workout.endTime!.difference(workout.startTime)
          : Duration.zero;

      final minutes = duration.inMinutes;
      final exercises = workout.exercises.length;
      final totalSets = workout.exercises.fold<int>(
        0,
        (sum, exercise) => sum + exercise.sets.length,
      );

      await _notificationService.showNotification(
        NotificationData(
          title: 'Workout Complete! 🎉',
          body: '$exercises exercises, $totalSets sets in $minutes minutes',
          type: NotificationType.workoutComplete,
          payload: {
            'workoutId': workout.id,
            'workoutType': workout.workoutType.toString(),
            'duration': duration.inSeconds.toString(),
          },
        ),
      );
    } catch (e, st) {
      _logger.warning('Failed to show workout complete notification', e, st);
    }
  }

  /// Schedule rest timer notification
  static Future<void> scheduleRestTimerNotification({
    required int restSeconds,
    String? exerciseName,
    int? setNumber,
  }) async {
    try {
      // Cancel previous rest timer notification if any
      await _notificationService.cancelNotification(999);

      final body = exerciseName != null && setNumber != null
          ? 'Time for set $setNumber of $exerciseName'
          : 'Time for your next set';

      await _notificationService.scheduleNotification(
        id: 999, // Fixed ID for rest timer
        notification: NotificationData(
          title: 'Rest Complete! ⏰',
          body: body,
          type: NotificationType.restTimer,
          payload: {
            'exerciseName': exerciseName ?? '',
            'setNumber': setNumber?.toString() ?? '',
          },
        ),
        scheduledTime: DateTime.now().add(Duration(seconds: restSeconds)),
      );

      _logger.info('Rest timer scheduled for $restSeconds seconds');
    } catch (e, st) {
      _logger.warning('Failed to schedule rest timer notification', e, st);
    }
  }

  /// Cancel rest timer notification
  static Future<void> cancelRestTimer() async {
    try {
      await _notificationService.cancelNotification(999);
      _logger.info('Rest timer cancelled');
    } catch (e, st) {
      _logger.warning('Failed to cancel rest timer', e, st);
    }
  }

  /// Setup or update daily workout reminder
  static Future<void> setupDailyWorkoutReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      await _notificationService.scheduleDailyNotification(
        id: 1, // Fixed ID for daily reminder
        notification: NotificationData(
          title: 'Time to Workout! 💪',
          body: 'Your body is ready for today\'s session',
          type: NotificationType.workoutReminder,
        ),
        hour: hour,
        minute: minute,
      );

      _logger.info('Daily workout reminder set for $hour:$minute');
    } catch (e, st) {
      _logger.warning('Failed to setup daily reminder', e, st);
    }
  }

  /// Cancel daily workout reminder
  static Future<void> cancelDailyWorkoutReminder() async {
    try {
      await _notificationService.cancelNotification(1);
      _logger.info('Daily workout reminder cancelled');
    } catch (e, st) {
      _logger.warning('Failed to cancel daily reminder', e, st);
    }
  }

  /// Show motivational notification (used sparingly)
  static Future<void> showMotivationalNotification({
    required String title,
    required String message,
  }) async {
    try {
      await _notificationService.showNotification(
        NotificationData(
          title: title,
          body: message,
          type: NotificationType.motivational,
        ),
      );
    } catch (e, st) {
      _logger.warning('Failed to show motivational notification', e, st);
    }
  }

  /// Show milestone notification (e.g., 10 workouts completed)
  static Future<void> showMilestoneNotification({
    required String milestone,
    required String message,
  }) async {
    try {
      await _notificationService.showNotification(
        NotificationData(
          title: 'Milestone Achieved! 🏆',
          body: '$milestone - $message',
          type: NotificationType.general,
          payload: {'milestone': milestone},
        ),
      );
    } catch (e, st) {
      _logger.warning('Failed to show milestone notification', e, st);
    }
  }

  /// Schedule a specific reminder notification (e.g., gym session appointment)
  static Future<void> scheduleWorkoutReminder({
    required DateTime scheduledTime,
    String? workoutName,
    int? notificationId,
  }) async {
    try {
      final id = notificationId ?? DateTime.now().millisecondsSinceEpoch;
      final body = workoutName != null
          ? 'Time for your $workoutName workout'
          : 'Time for your scheduled workout';

      await _notificationService.scheduleNotification(
        id: id,
        notification: NotificationData(
          title: 'Workout Reminder 🔔',
          body: body,
          type: NotificationType.workoutReminder,
          payload: {
            'workoutName': workoutName ?? '',
            'scheduledTime': scheduledTime.toIso8601String(),
          },
        ),
        scheduledTime: scheduledTime,
      );

      _logger.info('Workout reminder scheduled for $scheduledTime');
    } catch (e, st) {
      _logger.warning('Failed to schedule workout reminder', e, st);
    }
  }

  /// Get motivational messages for random notifications
  static List<Map<String, String>> get motivationalMessages => [
        {
          'title': 'Stay Strong! 💪',
          'message': 'Every workout brings you closer to your goals',
        },
        {
          'title': 'Keep Going! 🔥',
          'message': 'Progress is progress, no matter how small',
        },
        {
          'title': 'You Got This! ⚡',
          'message': 'Believe in yourself and your abilities',
        },
        {
          'title': 'Never Give Up! 🎯',
          'message': 'The only bad workout is the one that didn\'t happen',
        },
        {
          'title': 'Push Yourself! 💯',
          'message': 'Your future self will thank you',
        },
      ];

  /// Show a random motivational notification
  static Future<void> showRandomMotivationalNotification() async {
    try {
      final messages = motivationalMessages;
      final random = DateTime.now().millisecond % messages.length;
      final message = messages[random];

      await showMotivationalNotification(
        title: message['title']!,
        message: message['message']!,
      );
    } catch (e, st) {
      _logger.warning('Failed to show random motivational notification', e, st);
    }
  }
}
