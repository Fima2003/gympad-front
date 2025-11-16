import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'logger_service.dart';

/// Service managing local notifications for workout tracking.
/// Shows notifications when user leaves the app during a workout session.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AppLogger _logger = AppLogger();

  bool _isInitialized = false;

  // Notification IDs
  static const int _breakNotificationId = 100;
  static const int _setNotificationId = 101;

  // Channel IDs
  static const String _breakChannelId = 'workout_break';
  static const String _setChannelId = 'workout_set';

  // Action IDs
  static const String _actionAdd30s = 'add_30s';
  static const String _actionSkip = 'skip_break';
  static const String _actionFinish = 'finish_set';

  /// Callback for handling notification taps
  Future<void> Function(String?)? onNotificationTapped;

  /// Callback for handling action button taps
  Future<void> Function(String action)? onActionTapped;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize with callbacks
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      // Request permissions for iOS
      await _requestPermissions();

      _isInitialized = true;
      _logger.info('NotificationService initialized');
    } catch (e, st) {
      _logger.error('Failed to initialize NotificationService', e, st);
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    // Break notification channel
    const breakChannel = AndroidNotificationChannel(
      _breakChannelId,
      'Workout Break',
      description: 'Notifications during workout rest periods',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Set notification channel
    const setChannel = AndroidNotificationChannel(
      _setChannelId,
      'Workout Set',
      description: 'Notifications during workout sets',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(breakChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(setChannel);
  }

  /// Request notification permissions for iOS
  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Handle notification tap
  void _onNotificationResponse(NotificationResponse response) {
    _logger.info('Notification tapped: ${response.payload}');
    
    if (response.actionId != null) {
      // Action button was tapped
      onActionTapped?.call(response.actionId!);
    } else {
      // Notification body was tapped
      onNotificationTapped?.call(response.payload);
    }
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // This is called in a separate isolate, so we can't directly call callbacks
    // The main isolate will handle this through the notification stream
  }

  /// Show break notification with timer and next exercise info
  Future<void> showBreakNotification({
    required int remainingSeconds,
    required String nextExerciseName,
    String? nextExerciseWeight,
  }) async {
    if (!_isInitialized) {
      _logger.warning('NotificationService not initialized');
      return;
    }

    try {
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      final timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      final weightText = nextExerciseWeight != null ? ' • $nextExerciseWeight' : '';
      final subtitle = '$nextExerciseName$weightText';

      // Android-specific settings
      final androidDetails = AndroidNotificationDetails(
        _breakChannelId,
        'Workout Break',
        channelDescription: 'Notifications during workout rest periods',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        color: const Color(0xFF1a1a1a), // Break screen background color
        colorized: true,
        styleInformation: BigTextStyleInformation(
          subtitle,
          contentTitle: 'REST TIME • $timeText',
        ),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            _actionAdd30s,
            '+30s',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            _actionSkip,
            'Skip',
            showsUserInterface: true,
          ),
        ],
      );

      // iOS-specific settings
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _breakNotificationId,
        'REST TIME • $timeText',
        subtitle,
        notificationDetails,
        payload: 'break',
      );
    } catch (e, st) {
      _logger.error('Failed to show break notification', e, st);
    }
  }

  /// Show set notification with elapsed time and exercise info
  Future<void> showSetNotification({
    required int elapsedSeconds,
    required String exerciseName,
    required int currentSet,
    required int totalSets,
    required String finishButtonText, // "Finish Set", "Finish Exercise", or "Finish Workout"
  }) async {
    if (!_isInitialized) {
      _logger.warning('NotificationService not initialized');
      return;
    }

    try {
      final minutes = elapsedSeconds ~/ 60;
      final seconds = elapsedSeconds % 60;
      final timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      final subtitle = '$exerciseName • Set $currentSet of $totalSets';

      // Android-specific settings
      final androidDetails = AndroidNotificationDetails(
        _setChannelId,
        'Workout Set',
        channelDescription: 'Notifications during workout sets',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        color: const Color(0xFFF9F7F2), // Set screen background color
        colorized: true,
        styleInformation: BigTextStyleInformation(
          subtitle,
          contentTitle: 'SET IN PROGRESS • $timeText',
        ),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _actionFinish,
            finishButtonText,
            showsUserInterface: true,
          ),
        ],
      );

      // iOS-specific settings
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _setNotificationId,
        'SET IN PROGRESS • $timeText',
        subtitle,
        notificationDetails,
        payload: 'set',
      );
    } catch (e, st) {
      _logger.error('Failed to show set notification', e, st);
    }
  }

  /// Update the break notification with new remaining time
  Future<void> updateBreakNotification({
    required int remainingSeconds,
    required String nextExerciseName,
    String? nextExerciseWeight,
  }) async {
    // Simply call showBreakNotification again - it will update the existing notification
    await showBreakNotification(
      remainingSeconds: remainingSeconds,
      nextExerciseName: nextExerciseName,
      nextExerciseWeight: nextExerciseWeight,
    );
  }

  /// Update the set notification with new elapsed time
  Future<void> updateSetNotification({
    required int elapsedSeconds,
    required String exerciseName,
    required int currentSet,
    required int totalSets,
    required String finishButtonText,
  }) async {
    // Simply call showSetNotification again - it will update the existing notification
    await showSetNotification(
      elapsedSeconds: elapsedSeconds,
      exerciseName: exerciseName,
      currentSet: currentSet,
      totalSets: totalSets,
      finishButtonText: finishButtonText,
    );
  }

  /// Cancel break notification
  Future<void> cancelBreakNotification() async {
    await _notifications.cancel(_breakNotificationId);
  }

  /// Cancel set notification
  Future<void> cancelSetNotification() async {
    await _notifications.cancel(_setNotificationId);
  }

  /// Cancel all workout notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get the finish button text based on workout state
  String getFinishButtonText({
    required int currentSet,
    required int totalSets,
    required bool isLastExercise,
  }) {
    if (currentSet + 1 < totalSets) {
      return 'Finish Set';
    } else if (!isLastExercise) {
      return 'Finish Exercise';
    } else {
      return 'Finish Workout';
    }
  }
}
