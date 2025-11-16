import 'package:flutter/material.dart';
import '../../constants/app_styles.dart';
import '../../models/notification_data.dart';
import '../../services/logger_service.dart';
import '../../services/notification_service.dart';

/// Screen for managing notification settings and testing notifications.
///
/// This demonstrates how to integrate the NotificationService into UI.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _notificationService = NotificationService();
  final _logger = AppLogger().createLogger('NotificationSettingsScreen');

  NotificationSettings _settings = const NotificationSettings();
  bool _isLoading = true;
  int _selectedHour = 9;
  int _selectedMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _notificationService.getSettings();
      setState(() {
        _settings = settings;
        _selectedHour = settings.workoutReminderHour;
        _selectedMinute = settings.workoutReminderMinute;
        _isLoading = false;
      });
    } catch (e, st) {
      _logger.warning('Failed to load settings', e, st);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings(NotificationSettings newSettings) async {
    try {
      await _notificationService.updateSettings(newSettings);
      setState(() => _settings = newSettings);
      _showSnackBar('Settings updated');
    } catch (e, st) {
      _logger.warning('Failed to update settings', e, st);
      _showSnackBar('Failed to update settings');
    }
  }

  Future<void> _scheduleWorkoutReminder() async {
    try {
      await _notificationService.scheduleDailyNotification(
        id: 1,
        notification: NotificationData(
          title: 'Time to Workout! 💪',
          body: 'Your body is ready for today\'s session',
          type: NotificationType.workoutReminder,
        ),
        hour: _selectedHour,
        minute: _selectedMinute,
      );

      // Update settings with new time
      final newSettings = _settings.copyWith(
        workoutReminderHour: _selectedHour,
        workoutReminderMinute: _selectedMinute,
      );
      await _updateSettings(newSettings);

      _showSnackBar(
        'Daily reminder set for ${_formatTime(_selectedHour, _selectedMinute)}',
      );
    } catch (e, st) {
      _logger.warning('Failed to schedule reminder', e, st);
      _showSnackBar('Failed to schedule reminder');
    }
  }

  Future<void> _testNotification(NotificationType type) async {
    try {
      final notifications = {
        NotificationType.workoutComplete: NotificationData(
          title: 'Workout Complete! 🎉',
          body: 'Great job! You completed your workout',
          type: NotificationType.workoutComplete,
        ),
        NotificationType.restTimer: NotificationData(
          title: 'Rest Complete',
          body: 'Time for your next set!',
          type: NotificationType.restTimer,
        ),
        NotificationType.motivational: NotificationData(
          title: 'Stay Strong! 💪',
          body: 'Every workout brings you closer to your goals',
          type: NotificationType.motivational,
        ),
        NotificationType.workoutReminder: NotificationData(
          title: 'Time to Workout!',
          body: 'Don\'t skip your workout today',
          type: NotificationType.workoutReminder,
        ),
        NotificationType.general: NotificationData(
          title: 'GymPad Update',
          body: 'Check out new features in the app',
          type: NotificationType.general,
        ),
      };

      await _notificationService.showNotification(notifications[type]!);
      _showSnackBar('Test notification sent');
    } catch (e, st) {
      _logger.warning('Failed to send test notification', e, st);
      _showSnackBar('Failed to send notification');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'General Settings',
            [
              _buildSwitchTile(
                'Enable Notifications',
                'Receive notifications from GymPad',
                _settings.enabled,
                (value) => _updateSettings(_settings.copyWith(enabled: value)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Notification Types',
            [
              _buildSwitchTile(
                'Workout Reminders',
                'Get reminded about your daily workouts',
                _settings.workoutRemindersEnabled,
                (value) => _updateSettings(
                  _settings.copyWith(workoutRemindersEnabled: value),
                ),
                enabled: _settings.enabled,
              ),
              _buildSwitchTile(
                'Motivational Messages',
                'Receive inspiring messages',
                _settings.motivationalEnabled,
                (value) => _updateSettings(
                  _settings.copyWith(motivationalEnabled: value),
                ),
                enabled: _settings.enabled,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_settings.enabled && _settings.workoutRemindersEnabled)
            _buildSection(
              'Daily Reminder Time',
              [
                _buildTimePicker(),
                const SizedBox(height: 8),
                _buildButton(
                  'Set Daily Reminder',
                  () => _scheduleWorkoutReminder(),
                ),
              ],
            ),
          const SizedBox(height: 24),
          _buildSection(
            'Test Notifications',
            [
              _buildTestButton(
                'Test Workout Complete',
                NotificationType.workoutComplete,
              ),
              _buildTestButton(
                'Test Rest Timer',
                NotificationType.restTimer,
              ),
              _buildTestButton(
                'Test Motivational',
                NotificationType.motivational,
              ),
              _buildTestButton(
                'Test Workout Reminder',
                NotificationType.workoutReminder,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Manage Notifications',
            [
              _buildButton(
                'View Pending Notifications',
                () => _showPendingNotifications(),
              ),
              const SizedBox(height: 8),
              _buildButton(
                'Cancel All Notifications',
                () => _cancelAllNotifications(),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingM.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyL.copyWith(
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodyS.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: AppColors.accent,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTimePicker() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hour',
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: _selectedHour,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: List.generate(
                    24,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(
                        i.toString().padLeft(2, '0'),
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedHour = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minute',
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: _selectedMinute,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: List.generate(
                    60,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(
                        i.toString().padLeft(2, '0'),
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMinute = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {Color? color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyL.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, NotificationType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: _settings.enabled ? () => _testNotification(type) : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: _settings.enabled
                ? AppColors.accent
                : AppColors.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(text, style: AppTextStyles.bodyM),
      ),
    );
  }

  Future<void> _showPendingNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pending Notifications'),
          content: pending.isEmpty
              ? const Text('No pending notifications')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final notification = pending[index];
                      return ListTile(
                        title: Text(notification.title ?? 'No title'),
                        subtitle: Text(notification.body ?? 'No body'),
                        trailing: Text('ID: ${notification.id}'),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e, st) {
      _logger.warning('Failed to get pending notifications', e, st);
      _showSnackBar('Failed to load notifications');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      _showSnackBar('All notifications cancelled');
    } catch (e, st) {
      _logger.warning('Failed to cancel notifications', e, st);
      _showSnackBar('Failed to cancel notifications');
    }
  }
}
