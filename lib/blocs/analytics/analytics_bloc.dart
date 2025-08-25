import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/services/analytics_service.dart';

part 'analytics_event.dart';
part 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsService _analyticsService;
  AnalyticsBloc({AnalyticsService? analyticsService})
    : _analyticsService = analyticsService ?? AnalyticsService(),
      super(AInitialAnalyticsState()) {
    on<AStartedWorkout>(_onStartedWorkout);
    on<ACompletedWorkout>(_onEndedWorkout);
  }

  Future<void> _onStartedWorkout(
    AStartedWorkout event,
    Emitter<AnalyticsState> emit,
  ) async {
    unawaited(_analyticsService.incrementStartedWorkout());
  }

  Future<void> _onEndedWorkout(
    ACompletedWorkout event,
    Emitter<AnalyticsState> emit,
  ) async {
    unawaited(_analyticsService.incrementWorkoutCompleted());
  }
}
