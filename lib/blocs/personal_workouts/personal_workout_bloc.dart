import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/personal_workout.dart';
import '../../services/api/workout_api_service.dart';
import '../../services/hive/personal_workout_lss.dart';
import '../../services/logger_service.dart';

part 'personal_workout_events.dart';
part 'personal_workout_state.dart';

class PersonalWorkoutBloc
    extends Bloc<PersonalWorkoutEvent, PersonalWorkoutState> {
  final AppLogger _logger;
  final WorkoutApiService _workoutApi;
  final PersonalWorkoutLocalService _personalLocal =
      PersonalWorkoutLocalService();

  PersonalWorkoutBloc({WorkoutApiService? workoutApi, AppLogger? logger})
    : _workoutApi = workoutApi ?? WorkoutApiService(),
      _logger = logger ?? AppLogger(),
      super(const PersonalWorkoutInitial()) {
    on<RequestSync>(_onPersonalWorkoutsSyncRequested);
  }

  Future<void> _onPersonalWorkoutsSyncRequested(
    RequestSync event,
    Emitter<PersonalWorkoutState> emit,
  ) async {
    try {
      final resp = await _workoutApi.getPersonalWorkouts();
      if (resp.success && resp.data != null) {
        final list = resp.data!;
        await _personalLocal.saveAll(list);
        emit(
          PersonalWorkoutsLoaded(
            list.map((e) => PersonalWorkout.fromResponse(e)).toList(),
          ),
        );
      } else {
        // Fallback to local cache on failure
        final cached = await _personalLocal.loadAll();
        emit(PersonalWorkoutsLoaded(cached));
      }
    } catch (e, st) {
      _logger.error('Failed to sync personal workouts', e, st);
      final cached = await _personalLocal.loadAll();
      emit(PersonalWorkoutsLoaded(cached));
    }
  }
}
