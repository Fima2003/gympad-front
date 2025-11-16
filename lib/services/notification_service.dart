import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_data.dart';
import 'hive/notification_settings_lss.dart';
import 'logger_service.dart';

/// Centralized notification service for managing local notifications.
///
/// Features:
/// - Show instant notifications
/// - Schedule notifications for future delivery
/// - Cancel individual or all notifications
/// - Manage notification settings/preferences
/// - Handle notification taps and responses
///
/// Usage:
/// ```dart
/// final notificationService = NotificationService();
/// await notificationService.initialize();
///
/// // Show instant notification
/// await notificationService.showNotification(
///   NotificationData(
///     title: 'Workout Complete!',
///     body: 'Great job finishing your workout',
///     type: NotificationType.workoutComplete,
///   ),
/// );
///
/// // Schedule notification
/// await notificationService.scheduleNotification(
///   id: 1,
///   notification: NotificationData(
///     title: 'Time to Workout',
///     body: 'Don\'t forget your daily workout',
///     type: NotificationType.workoutReminder,
///   ),
///   scheduledTime: DateTime.now().add(Duration(hours: 24)),
/// );
/// ```
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationSettingsLss _settingsStorage = NotificationSettingsLss();
  final Logger _logger = AppLogger().createLogger('NotificationService');

  // Notification channel IDs for Android
  static const String _workoutChannelId = 'workout_channel';
  static const String _generalChannelId = 'general_channel';
  static const String _motivationalChannelId = 'motivational_channel';

  bool _initialized = false;
  NotificationSettings? _cachedSettings;

  /// Stream controller for notification tap events
  final _notificationTapController =
      StreamController<NotificationData>.broadcast();

  /// Stream of notification tap events
  Stream<NotificationData> get notificationTapStream =>
      _notificationTapController.stream;

  /// Indicates whether the service has been initialized
  bool get isInitialized => _initialized;

  /// Initialize the notification service.
  ///
  /// Must be called before using any other methods.
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) {
      _logger.fine('NotificationService already initialized');
      return;
    }

    try {
      _logger.info('Initializing NotificationService');

      // Initialize timezone data for scheduled notifications
      tz.initializeTimeZones();

      // Load cached settings
      _cachedSettings = await _settingsStorage.get();
      _cachedSettings ??= const NotificationSettings();
      await _settingsStorage.save(_cachedSettings!);

      // Platform-specific initialization
      if (!kIsWeb) {
        await _initializePlatformNotifications();
      } else {
        _logger.warning('Notifications not supported on web platform');
      }

      _initialized = true;
      _logger.info('NotificationService initialized successfully');
    } catch (e, st) {
      _logger.severe('Failed to initialize NotificationService', e, st);
      rethrow;
    }
  }

  /// Initialize platform-specific notification settings
  Future<void> _initializePlatformNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

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

    // Initialize with callback for when notification is tapped
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions (especially important for iOS)
    if (Platform.isIOS) {
      await _requestIOSPermissions();
    } else if (Platform.isAndroid) {
      await _createAndroidNotificationChannels();
    }

    _logger.info('Platform notifications initialized');
  }

  /// Request notification permissions on iOS
  Future<bool> _requestIOSPermissions() async {
    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      _logger.info('iOS notification permissions granted: $result');
      return result ?? false;
    } catch (e, st) {
      _logger.warning('Failed to request iOS permissions', e, st);
      return false;
    }
  }

  /// Create notification channels for Android (required for Android 8.0+)
  Future<void> _createAndroidNotificationChannels() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) return;

      // Workout channel - high priority
      const workoutChannel = AndroidNotificationChannel(
        _workoutChannelId,
        'Workout Notifications',
        description: 'Notifications related to workouts and exercise tracking',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // General channel - default priority
      const generalChannel = AndroidNotificationChannel(
        _generalChannelId,
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
        playSound: true,
      );

      // Motivational channel - low priority
      const motivationalChannel = AndroidNotificationChannel(
        _motivationalChannelId,
        'Motivational Notifications',
        description: 'Motivational messages and reminders',
        importance: Importance.low,
        playSound: false,
      );

      await androidPlugin.createNotificationChannel(workoutChannel);
      await androidPlugin.createNotificationChannel(generalChannel);
      await androidPlugin.createNotificationChannel(motivationalChannel);

      _logger.info('Android notification channels created');
    } catch (e, st) {
      _logger.warning('Failed to create Android channels', e, st);
    }
  }

  /// Handle notification tap events
  void _onNotificationTapped(NotificationResponse response) {
    try {
      _logger.info('Notification tapped: ${response.payload}');

      if (response.payload != null) {
        // Parse payload and emit to stream
        final notificationData = NotificationData.fromJson(
          Map<String, dynamic>.from(
            Uri.splitQueryString(response.payload!),
          ),
        );
        _notificationTapController.add(notificationData);
      }
    } catch (e, st) {
      _logger.warning('Failed to handle notification tap', e, st);
    }
  }

  /// Show an instant notification
  Future<void> showNotification(
    NotificationData notification, {
    int? id,
  }) async {
    if (!_initialized) {
      _logger.warning('NotificationService not initialized');
      return;
    }

    // Check if notifications are enabled
    final settings = await getSettings();
    if (!settings.enabled) {
      _logger.fine('Notifications disabled, skipping');
      return;
    }

    // Check type-specific settings
    if (!_isNotificationTypeEnabled(notification.type, settings)) {
      _logger.fine(
        'Notification type ${notification.type} disabled, skipping',
      );
      return;
    }

    try {
      final notificationId = id ?? notification.hashCode;
      final channelId = _getChannelId(notification.type);
      final payload = notification.toJson().toString();

      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(notification.type),
        channelDescription: _getChannelDescription(notification.type),
        importance: _getImportance(notification.type),
        priority: _getPriority(notification.type),
        playSound: true,
        enableVibration: notification.type == NotificationType.workoutComplete,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
        notification.title,
        notification.body,
        details,
        payload: payload,
      );

      _logger.info('Notification shown: ${notification.title}');
    } catch (e, st) {
      _logger.severe('Failed to show notification', e, st);
    }
  }

  /// Schedule a notification for future delivery
  Future<void> scheduleNotification({
    required int id,
    required NotificationData notification,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) {
      _logger.warning('NotificationService not initialized');
      return;
    }

    final settings = await getSettings();
    if (!settings.enabled) {
      _logger.fine('Notifications disabled, skipping schedule');
      return;
    }

    if (!_isNotificationTypeEnabled(notification.type, settings)) {
      _logger.fine(
        'Notification type ${notification.type} disabled, skipping schedule',
      );
      return;
    }

    try {
      final channelId = _getChannelId(notification.type);
      final payload = notification.toJson().toString();

      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(notification.type),
        channelDescription: _getChannelDescription(notification.type),
        importance: _getImportance(notification.type),
        priority: _getPriority(notification.type),
      );

      const iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        notification.title,
        notification.body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      _logger.info(
        'Notification scheduled: ${notification.title} at $scheduledTime',
      );
    } catch (e, st) {
      _logger.severe('Failed to schedule notification', e, st);
    }
  }

  /// Schedule a daily notification at a specific time
  Future<void> scheduleDailyNotification({
    required int id,
    required NotificationData notification,
    required int hour, // 0-23
    required int minute, // 0-59
  }) async {
    if (!_initialized) {
      _logger.warning('NotificationService not initialized');
      return;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the scheduled time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await scheduleNotification(
        id: id,
        notification: notification,
        scheduledTime: scheduledDate,
      );

      _logger.info(
        'Daily notification scheduled at $hour:$minute',
      );
    } catch (e, st) {
      _logger.severe('Failed to schedule daily notification', e, st);
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      _logger.info('Notification cancelled: $id');
    } catch (e, st) {
      _logger.warning('Failed to cancel notification', e, st);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logger.info('All notifications cancelled');
    } catch (e, st) {
      _logger.warning('Failed to cancel all notifications', e, st);
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e, st) {
      _logger.warning('Failed to get pending notifications', e, st);
      return [];
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getSettings() async {
    try {
      _cachedSettings ??= await _settingsStorage.get();
      return _cachedSettings ?? const NotificationSettings();
    } catch (e, st) {
      _logger.warning('Failed to get settings, using defaults', e, st);
      return const NotificationSettings();
    }
  }

  /// Update notification settings
  Future<void> updateSettings(NotificationSettings settings) async {
    try {
      await _settingsStorage.save(settings);
      _cachedSettings = settings;
      _logger.info('Notification settings updated');

      // If notifications are disabled, cancel all pending notifications
      if (!settings.enabled) {
        await cancelAllNotifications();
      }
    } catch (e, st) {
      _logger.severe('Failed to update settings', e, st);
      rethrow;
    }
  }

  /// Check if a specific notification type is enabled
  bool _isNotificationTypeEnabled(
    NotificationType type,
    NotificationSettings settings,
  ) {
    switch (type) {
      case NotificationType.workoutReminder:
        return settings.workoutRemindersEnabled;
      case NotificationType.motivational:
        return settings.motivationalEnabled;
      case NotificationType.restTimer:
      case NotificationType.workoutComplete:
      case NotificationType.general:
        return true; // Always enabled if notifications are enabled
    }
  }

  /// Get channel ID for notification type
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.workoutReminder:
      case NotificationType.restTimer:
      case NotificationType.workoutComplete:
        return _workoutChannelId;
      case NotificationType.motivational:
        return _motivationalChannelId;
      case NotificationType.general:
        return _generalChannelId;
    }
  }

  /// Get channel name for notification type
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.workoutReminder:
      case NotificationType.restTimer:
      case NotificationType.workoutComplete:
        return 'Workout Notifications';
      case NotificationType.motivational:
        return 'Motivational Notifications';
      case NotificationType.general:
        return 'General Notifications';
    }
  }

  /// Get channel description for notification type
  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.workoutReminder:
      case NotificationType.restTimer:
      case NotificationType.workoutComplete:
        return 'Notifications related to workouts and exercise tracking';
      case NotificationType.motivational:
        return 'Motivational messages and reminders';
      case NotificationType.general:
        return 'General app notifications';
    }
  }

  /// Get Android importance level for notification type
  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.workoutReminder:
      case NotificationType.workoutComplete:
        return Importance.high;
      case NotificationType.restTimer:
        return Importance.max;
      case NotificationType.motivational:
        return Importance.low;
      case NotificationType.general:
        return Importance.defaultImportance;
    }
  }

  /// Get Android priority for notification type
  Priority _getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.workoutReminder:
      case NotificationType.workoutComplete:
        return Priority.high;
      case NotificationType.restTimer:
        return Priority.max;
      case NotificationType.motivational:
        return Priority.low;
      case NotificationType.general:
        return Priority.defaultPriority;
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}
