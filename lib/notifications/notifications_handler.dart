import 'dart:async';
import 'package:flutter/widgets.dart';
import '../blocs/workout/workout_bloc.dart';
import '../blocs/data/data_bloc.dart';
import '../blocs/user_settings/user_settings_bloc.dart';
import '../services/notification_service.dart';
import '../services/logger_service.dart';
import '../utils/get_weight.dart';

/// Handles integration between app lifecycle, workout state, and notifications
class NotificationsHandler with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final AppLogger _logger = AppLogger();
  
  WorkoutBloc? _workoutBloc;
  DataBloc? _dataBloc;
  UserSettingsBloc? _userSettingsBloc;
  StreamSubscription<WorkoutState>? _workoutSubscription;
  Timer? _notificationUpdateTimer;
  
  WorkoutState? _lastWorkoutState;
  bool _isInBackground = false;

  /// Initialize the handler with necessary blocs
  Future<void> initialize({
    required WorkoutBloc workoutBloc,
    required DataBloc dataBloc,
    required UserSettingsBloc userSettingsBloc,
  }) async {
    _workoutBloc = workoutBloc;
    _dataBloc = dataBloc;
    _userSettingsBloc = userSettingsBloc;

    // Initialize notification service
    await _notificationService.initialize();

    // Set up notification callbacks
    _notificationService.onNotificationTapped = _handleNotificationTap;
    _notificationService.onActionTapped = _handleActionTap;

    // Listen to workout state changes
    _workoutSubscription = _workoutBloc?.stream.listen(_onWorkoutStateChanged);

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _logger.info('NotificationsHandler initialized');
  }

  /// Clean up resources
  void dispose() {
    _workoutSubscription?.cancel();
    _notificationUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _notificationService.cancelAllNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.info('App lifecycle changed: $state');

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background
      _isInBackground = true;
      _showNotificationIfNeeded(_lastWorkoutState);
      _startNotificationUpdateTimer();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground
      _isInBackground = false;
      _stopNotificationUpdateTimer();
      _notificationService.cancelAllNotifications();
    }
  }

  /// Handle workout state changes
  void _onWorkoutStateChanged(WorkoutState state) {
    _lastWorkoutState = state;
    
    if (_isInBackground) {
      _showNotificationIfNeeded(state);
    } else {
      // If in foreground, cancel all notifications
      _notificationService.cancelAllNotifications();
    }
  }

  /// Show appropriate notification based on workout state
  void _showNotificationIfNeeded(WorkoutState? state) {
    if (state == null) return;

    if (state is WorkoutRunRest) {
      _showBreakNotification(state);
    } else if (state is WorkoutRunInSet) {
      _showSetNotification(state);
    } else {
      // No active workout phase, cancel notifications
      _notificationService.cancelAllNotifications();
      _stopNotificationUpdateTimer();
    }
  }

  /// Show break notification
  Future<void> _showBreakNotification(WorkoutRunRest state) async {
    final nextExercise = state.nextExercise;
    if (nextExercise == null) return;

    // Get exercise name from data bloc
    String exerciseName = nextExercise.id.toUpperCase();
    if (_dataBloc?.state is DataReady) {
      final dataState = _dataBloc!.state as DataReady;
      final exercise = dataState.exercises[nextExercise.id];
      if (exercise != null) {
        exerciseName = exercise.name.toUpperCase();
      }
    }

    // Get weight with proper unit
    String? weightText;
    if (nextExercise.suggestedWeight != null && nextExercise.suggestedWeight! > 0) {
      final userSettingsState = _userSettingsBloc?.state;
      if (userSettingsState is UserSettingsLoaded) {
        weightText = getWeightString(
          nextExercise.suggestedWeight!,
          userSettingsState.weightUnit,
        );
      } else {
        weightText = '${nextExercise.suggestedWeight}kg';
      }
      if (nextExercise.suggestedReps != null) {
        weightText = '${nextExercise.suggestedReps} x $weightText';
      }
    }

    await _notificationService.showBreakNotification(
      remainingSeconds: state.remaining.inSeconds,
      nextExerciseName: exerciseName,
      nextExerciseWeight: weightText,
    );
  }

  /// Show set notification
  Future<void> _showSetNotification(WorkoutRunInSet state) async {
    final currentExercise = state.currentExercise;

    // Get exercise name from data bloc
    String exerciseName = currentExercise.id.toUpperCase();
    if (_dataBloc?.state is DataReady) {
      final dataState = _dataBloc!.state as DataReady;
      final exercise = dataState.exercises[currentExercise.id];
      if (exercise != null) {
        exerciseName = exercise.name.toUpperCase();
      }
    }

    // Determine finish button text based on finishType
    String finishButtonText;
    switch (state.finishType) {
      case RunFinishType.set:
        finishButtonText = 'Finish Set';
        break;
      case RunFinishType.exercise:
        finishButtonText = 'Finish Exercise';
        break;
      case RunFinishType.workout:
        finishButtonText = 'Finish Workout';
        break;
    }

    await _notificationService.showSetNotification(
      elapsedSeconds: state.elapsed.inSeconds,
      exerciseName: exerciseName,
      currentSet: state.currentSetIdx + 1,
      totalSets: currentExercise.setsAmount,
      finishButtonText: finishButtonText,
    );
  }

  /// Start timer to update notifications periodically
  void _startNotificationUpdateTimer() {
    _stopNotificationUpdateTimer();
    
    _notificationUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _showNotificationIfNeeded(_lastWorkoutState),
    );
  }

  /// Stop notification update timer
  void _stopNotificationUpdateTimer() {
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = null;
  }

  /// Handle notification tap (when user taps notification body)
  Future<void> _handleNotificationTap(String? payload) async {
    _logger.info('Notification tapped with payload: $payload');
    
    // The app will already be brought to foreground by the system
    // Notifications will be cancelled automatically in didChangeAppLifecycleState
    
    // Optionally navigate to specific screen based on payload
    // This would require access to navigation/router which we don't have here
    // The app will show the current workout state when resumed
  }

  /// Handle action button tap
  Future<void> _handleActionTap(String action) async {
    _logger.info('Notification action tapped: $action');

    if (_workoutBloc == null) return;

    switch (action) {
      case 'add_30s':
        // Add 30 seconds to rest timer
        _workoutBloc!.add(const RunExtendRest(seconds: 30));
        break;
        
      case 'skip_break':
        // Skip the rest period
        _workoutBloc!.add(const RunSkipRest());
        break;
        
      case 'finish_set':
        // This should open the reps dialog, but we can't do that from here
        // The app will be brought to foreground and show the current state
        // User will need to tap the finish button again in the app
        break;
    }
  }
}
