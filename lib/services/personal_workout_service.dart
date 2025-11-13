import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../models/capabilities.dart';
import '../models/personal_workout.dart';
import 'api/models/personal_workout.model.dart';
import 'api/workout_api_service.dart';
import 'hive/personal_workout_lss.dart';
import 'logger_service.dart';

class PersonalWorkoutService {
  static final PersonalWorkoutService _instance =
      PersonalWorkoutService._internal();
  factory PersonalWorkoutService() => _instance;

  PersonalWorkoutService._internal() {
    _personalWorkoutsController = BehaviorSubject<List<PersonalWorkout>>();
  }

  final Logger _logger = AppLogger().createLogger('PersonalWorkoutService');
  final PersonalWorkoutLocalService _personalLocal =
      PersonalWorkoutLocalService();
  CapabilitiesProvider _capabilitiesProvider = () => Capabilities.guest;

  void configureCapabilitiesProvider(CapabilitiesProvider provider) {
    _capabilitiesProvider = provider;
  }

  final WorkoutApiService _personalWorkoutApiService = WorkoutApiService();

  // BehaviorSubject replays the last emitted value to new subscribers
  late final BehaviorSubject<List<PersonalWorkout>> _personalWorkoutsController;

  /// Stream of personal workouts updates.
  /// Emits the cached workouts immediately to new subscribers, then any future updates.
  Stream<List<PersonalWorkout>> get personalWorkoutsStream =>
      _personalWorkoutsController.stream;

  Future<bool> savePersonalWorkout(CreatePersonalWorkoutRequest req) async {
    final resp = await WorkoutApiService().createPersonalWorkout(req);
    return resp.fold(
      onError: (_) => false,
      onSuccess: (id) {
        _personalLocal.save(req.toDomain(id));
        _personalWorkoutsController.add([
          ..._personalWorkoutsController.value,
          req.toDomain(id),
        ]);
        _personalLocal.setEtag(resp.etag);
        return true;
      },
    );
  }

  /// Initialize personal workouts by loading from cache and syncing with API.
  ///
  /// Flow:
  /// 1. Immediately emit cached workouts from local storage
  /// 2. Fetch fresh workouts from API in the background (non-blocking)
  /// 3. If API returns new data (not error, not 304), update local storage and emit
  /// 4. Otherwise, keep using local cache silently
  Future<void> initializePersonalWorkouts() async {
    try {
      // Step 1: Load and emit cached workouts immediately
      final cachedWorkouts = await _personalLocal.getAll();
      _personalWorkoutsController.add(cachedWorkouts);
      _logger.info(
        'Emitted ${cachedWorkouts.length} cached personal workouts to stream',
      );

      // Step 2: Sync fresh workouts from API in the background (non-blocking)
      unawaited(_syncPersonalWorkoutsFromApi());
    } catch (e) {
      _logger.severe('Error in initializePersonalWorkouts: $e');
      _personalWorkoutsController.addError(e);
    }
  }

  /// Sync personal workouts from API in the background.
  ///
  /// Only updates local storage and emits if API returns fresh data.
  /// Silently keeps local cache if API returns 304 or errors.
  Future<void> _syncPersonalWorkoutsFromApi() async {
    try {
      final caps = _capabilitiesProvider();
      if (!caps.canSync) {
        _logger.info('Skipping syncing personal workouts (guest mode)');
        return;
      }
      print(await _personalLocal.getEtag());

      final result = await _personalWorkoutApiService.getPersonalWorkouts(await _personalLocal.getEtag());
      await result.foldAsync(
        onError: (error) async {
          if (error.status == 304) {
            // Not modified - keep using cached data
            _logger.info(
              'Personal workouts not modified (304), keeping local cache',
            );
          } else {
            // API error - keep using cached data, just log the issue
            _logger.warning(
              'Failed to sync personal workouts from API: $error',
            );
          }
        },
        onSuccess: (data) async {
          // Fresh data from API - update local storage and emit
          _logger.info(
            'Received ${data.length} personal workouts from API, updating cache',
          );
          unawaited(_personalLocal.saveMany(data));
          unawaited(_personalLocal.setEtag(result.etag));
          _personalWorkoutsController.add(data);
        },
      );
    } catch (e) {
      _logger.severe('Error syncing personal workouts from API: $e');
    }
  }

  /// Cleanup resources when service is no longer needed.
  void dispose() {
    _personalWorkoutsController.close();
  }
}
