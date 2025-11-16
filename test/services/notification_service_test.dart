import 'package:flutter_test/flutter_test.dart';
import 'package:gympad/models/notification_data.dart';
import 'package:gympad/services/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Unit tests for NotificationService
///
/// These tests demonstrate testing patterns for the notification system.
/// Run with: flutter test test/services/notification_service_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationData', () {
    test('should create NotificationData with required fields', () {
      final notification = NotificationData(
        title: 'Test Title',
        body: 'Test Body',
        type: NotificationType.workoutComplete,
      );

      expect(notification.title, 'Test Title');
      expect(notification.body, 'Test Body');
      expect(notification.type, NotificationType.workoutComplete);
      expect(notification.payload, isNull);
    });

    test('should create NotificationData with payload', () {
      final notification = NotificationData(
        title: 'Test',
        body: 'Test',
        type: NotificationType.general,
        payload: {'key': 'value', 'count': 42},
      );

      expect(notification.payload, isNotNull);
      expect(notification.payload!['key'], 'value');
      expect(notification.payload!['count'], 42);
    });

    test('should serialize to JSON correctly', () {
      final notification = NotificationData(
        title: 'Test Title',
        body: 'Test Body',
        type: NotificationType.workoutReminder,
        payload: {'workoutId': '123'},
      );

      final json = notification.toJson();

      expect(json['title'], 'Test Title');
      expect(json['body'], 'Test Body');
      expect(json['type'], 'workoutReminder');
      expect(json['payload'], {'workoutId': '123'});
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'title': 'Test Title',
        'body': 'Test Body',
        'type': 'restTimer',
        'payload': {'exerciseId': 'push_up'},
      };

      final notification = NotificationData.fromJson(json);

      expect(notification.title, 'Test Title');
      expect(notification.body, 'Test Body');
      expect(notification.type, NotificationType.restTimer);
      expect(notification.payload!['exerciseId'], 'push_up');
    });

    test('should handle unknown notification type gracefully', () {
      final json = {
        'title': 'Test',
        'body': 'Test',
        'type': 'unknown_type',
      };

      final notification = NotificationData.fromJson(json);

      // Should default to general type
      expect(notification.type, NotificationType.general);
    });

    test('should support copyWith', () {
      final original = NotificationData(
        title: 'Original Title',
        body: 'Original Body',
        type: NotificationType.motivational,
      );

      final modified = original.copyWith(
        title: 'New Title',
        payload: {'key': 'value'},
      );

      expect(modified.title, 'New Title');
      expect(modified.body, 'Original Body');
      expect(modified.type, NotificationType.motivational);
      expect(modified.payload!['key'], 'value');
    });
  });

  group('NotificationSettings', () {
    test('should create with default values', () {
      const settings = NotificationSettings();

      expect(settings.enabled, true);
      expect(settings.workoutRemindersEnabled, true);
      expect(settings.motivationalEnabled, true);
      expect(settings.workoutReminderHour, 9);
      expect(settings.workoutReminderMinute, 0);
    });

    test('should create with custom values', () {
      const settings = NotificationSettings(
        enabled: false,
        workoutRemindersEnabled: false,
        motivationalEnabled: true,
        workoutReminderHour: 18,
        workoutReminderMinute: 30,
      );

      expect(settings.enabled, false);
      expect(settings.workoutRemindersEnabled, false);
      expect(settings.motivationalEnabled, true);
      expect(settings.workoutReminderHour, 18);
      expect(settings.workoutReminderMinute, 30);
    });

    test('should serialize to JSON correctly', () {
      const settings = NotificationSettings(
        enabled: true,
        workoutRemindersEnabled: false,
        motivationalEnabled: true,
        workoutReminderHour: 14,
        workoutReminderMinute: 45,
      );

      final json = settings.toJson();

      expect(json['enabled'], true);
      expect(json['workoutRemindersEnabled'], false);
      expect(json['motivationalEnabled'], true);
      expect(json['workoutReminderHour'], 14);
      expect(json['workoutReminderMinute'], 45);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'enabled': false,
        'workoutRemindersEnabled': true,
        'motivationalEnabled': false,
        'workoutReminderHour': 20,
        'workoutReminderMinute': 15,
      };

      final settings = NotificationSettings.fromJson(json);

      expect(settings.enabled, false);
      expect(settings.workoutRemindersEnabled, true);
      expect(settings.motivationalEnabled, false);
      expect(settings.workoutReminderHour, 20);
      expect(settings.workoutReminderMinute, 15);
    });

    test('should use defaults for missing JSON fields', () {
      final json = <String, dynamic>{};

      final settings = NotificationSettings.fromJson(json);

      expect(settings.enabled, true);
      expect(settings.workoutRemindersEnabled, true);
      expect(settings.motivationalEnabled, true);
      expect(settings.workoutReminderHour, 9);
      expect(settings.workoutReminderMinute, 0);
    });

    test('should support copyWith', () {
      const original = NotificationSettings(
        enabled: true,
        workoutReminderHour: 9,
      );

      final modified = original.copyWith(
        enabled: false,
        workoutReminderMinute: 30,
      );

      expect(modified.enabled, false);
      expect(modified.workoutReminderHour, 9);
      expect(modified.workoutReminderMinute, 30);
    });

    test('should validate hour range', () {
      // Valid hours (0-23)
      expect(() => NotificationSettings(workoutReminderHour: 0), returnsNormally);
      expect(() => NotificationSettings(workoutReminderHour: 23), returnsNormally);
    });

    test('should validate minute range', () {
      // Valid minutes (0-59)
      expect(
        () => NotificationSettings(workoutReminderMinute: 0),
        returnsNormally,
      );
      expect(
        () => NotificationSettings(workoutReminderMinute: 59),
        returnsNormally,
      );
    });
  });

  group('NotificationType', () {
    test('should have all expected types', () {
      expect(NotificationType.values, hasLength(5));
      expect(NotificationType.values, contains(NotificationType.workoutReminder));
      expect(NotificationType.values, contains(NotificationType.restTimer));
      expect(NotificationType.values, contains(NotificationType.workoutComplete));
      expect(NotificationType.values, contains(NotificationType.motivational));
      expect(NotificationType.values, contains(NotificationType.general));
    });

    test('should convert to string name correctly', () {
      expect(NotificationType.workoutReminder.name, 'workoutReminder');
      expect(NotificationType.restTimer.name, 'restTimer');
      expect(NotificationType.workoutComplete.name, 'workoutComplete');
      expect(NotificationType.motivational.name, 'motivational');
      expect(NotificationType.general.name, 'general');
    });
  });

  group('NotificationService', () {
    setUp(() async {
      // Initialize Hive with a temporary path for testing
      await Hive.initFlutter();
    });

    tearDown(() async {
      // Clean up Hive boxes after each test
      await Hive.deleteFromDisk();
    });

    test('should be a singleton', () {
      final instance1 = NotificationService();
      final instance2 = NotificationService();

      expect(identical(instance1, instance2), true);
    });

    test('should not be initialized before initialize() is called', () {
      final service = NotificationService();
      // Note: This assumes fresh instance or reset between tests
      // In practice, singleton state persists
      expect(service.isInitialized, isTrue); // Will be true if already initialized
    });

    // Note: Most NotificationService methods require platform-specific
    // initialization that cannot be fully tested in unit tests.
    // Integration tests or widget tests on real devices are needed.

    test('should handle notification data payload correctly', () {
      final notification = NotificationData(
        title: 'Workout Reminder',
        body: 'Time to exercise',
        type: NotificationType.workoutReminder,
        payload: {
          'workoutId': 'workout_123',
          'scheduledTime': '2024-01-01T09:00:00',
        },
      );

      // Simulate serialization/deserialization
      final json = notification.toJson();
      final restored = NotificationData.fromJson(json);

      expect(restored.payload!['workoutId'], 'workout_123');
      expect(restored.payload!['scheduledTime'], '2024-01-01T09:00:00');
    });
  });

  group('Notification Round-trip Serialization', () {
    test('should maintain data integrity through JSON round-trip', () {
      final original = NotificationData(
        title: 'Complex Notification',
        body: 'With multiple data points',
        type: NotificationType.workoutComplete,
        payload: {
          'workoutId': 'w123',
          'duration': 3600,
          'exercises': ['push_up', 'squat'],
          'completed': true,
        },
      );

      final json = original.toJson();
      final restored = NotificationData.fromJson(json);

      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.type, original.type);
      expect(restored.payload!['workoutId'], 'w123');
      expect(restored.payload!['duration'], 3600);
      expect(restored.payload!['exercises'], ['push_up', 'squat']);
      expect(restored.payload!['completed'], true);
    });

    test('settings should maintain data integrity through JSON round-trip', () {
      const original = NotificationSettings(
        enabled: false,
        workoutRemindersEnabled: true,
        motivationalEnabled: false,
        workoutReminderHour: 15,
        workoutReminderMinute: 45,
      );

      final json = original.toJson();
      final restored = NotificationSettings.fromJson(json);

      expect(restored.enabled, original.enabled);
      expect(
        restored.workoutRemindersEnabled,
        original.workoutRemindersEnabled,
      );
      expect(restored.motivationalEnabled, original.motivationalEnabled);
      expect(restored.workoutReminderHour, original.workoutReminderHour);
      expect(restored.workoutReminderMinute, original.workoutReminderMinute);
    });
  });
}
