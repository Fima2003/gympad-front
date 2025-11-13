import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../models/personal_workout.dart';
import '../../services/logger_service.dart';
import '../../services/personal_workout_service.dart';

part 'personal_workout_events.dart';
part 'personal_workout_state.dart';

class PersonalWorkoutBloc
    extends Bloc<PersonalWorkoutEvent, PersonalWorkoutState> {
  final Logger _logger;
  final PersonalWorkoutService _personalWorkoutService;

  PersonalWorkoutBloc({PersonalWorkoutService? workout, Logger? logger})
    : _personalWorkoutService = workout ?? PersonalWorkoutService(),
      _logger = logger ?? AppLogger().createLogger('PersonalWorkoutBloc'),
      super(const PersonalWorkoutInitial()) {
    on<RequestSync>(_onPersonalWorkoutsSyncRequested);
  }

  /// Load personal workouts and subscribe to updates.
  /// This initializes the service and starts listening to the stream.
  Future<void> _onPersonalWorkoutsSyncRequested(
    RequestSync event,
    Emitter<PersonalWorkoutState> emit,
  ) async {
    try {
      // Initialize workouts (loads cache + starts API sync)
      await _personalWorkoutService.initializePersonalWorkouts();

      // Use emit.forEach to properly handle stream emissions
      await emit.forEach<List<PersonalWorkout>>(
        _personalWorkoutService.personalWorkoutsStream,
        onData: (workouts) {
          _logger.info('Loaded ${workouts.length} personal workouts');
          return PersonalWorkoutsLoaded(workouts);
        },
        onError: (error, stackTrace) {
          _logger.severe(
            'Error loading personal workouts: $error',
            error,
            stackTrace,
          );
          // Keep current state on error instead of transitioning
          return state;
        },
      );
    } catch (e) {
      _logger.severe('Error in _onPersonalWorkoutsSyncRequested: $e');
      emit(const PersonalWorkoutInitial());
    }
  }

  @override
  Future<void> close() {
    _personalWorkoutService.dispose();
    return super.close();
  }
}
