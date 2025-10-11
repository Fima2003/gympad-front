import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/services/workout_service.dart';

import '../../models/personal_workout.dart';
import '../../services/logger_service.dart';

part 'personal_workout_events.dart';
part 'personal_workout_state.dart';

class PersonalWorkoutBloc
    extends Bloc<PersonalWorkoutEvent, PersonalWorkoutState> {
  final AppLogger _logger;
  final WorkoutService _workoutService;

  PersonalWorkoutBloc({WorkoutService? workout, AppLogger? logger})
    : _workoutService = workout ?? WorkoutService(),
      _logger = logger ?? AppLogger(),
      super(const PersonalWorkoutInitial()) {
    on<RequestSync>(_onPersonalWorkoutsSyncRequested);
  }

  Future<void> _onPersonalWorkoutsSyncRequested(
    RequestSync event,
    Emitter<PersonalWorkoutState> emit,
  ) async {
    emit(const PersonalWorkoutsLoading());
    final List<PersonalWorkout> personalWorkouts =
        await _workoutService.getPersonalWorkouts();
    _logger.info('Loaded ${personalWorkouts.length} personal workouts');
    emit(PersonalWorkoutsLoaded(personalWorkouts));
  }
}
