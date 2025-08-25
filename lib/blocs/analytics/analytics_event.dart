part of 'analytics_bloc.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class AStartedWorkout extends AnalyticsEvent {}

class ACompletedWorkout extends AnalyticsEvent {}

class AInitialAnalyticsState extends AnalyticsState {}
