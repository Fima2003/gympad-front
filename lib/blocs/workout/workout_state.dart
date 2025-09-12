part of 'workout_bloc.dart';

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class WorkoutInProgress extends WorkoutState {
  final Workout workout;
  final CustomWorkout? workoutToFollow;
  final int currentExerciseIdx;
  final int currentSetIdx;
  final double? progress; // between 0 to 100

  const WorkoutInProgress(
    this.workout, {
    this.workoutToFollow,
    required this.currentExerciseIdx,
    required this.currentSetIdx,
    this.progress,
  });

  @override
  List<Object?> get props => [
    workout,
    workoutToFollow,
    currentExerciseIdx,
    currentSetIdx,
    progress,
  ];
}

class AddingExercise extends WorkoutState {}

class WorkoutCompleted extends WorkoutState {
  final Workout workout;

  const WorkoutCompleted(this.workout);

  @override
  List<Object> get props => [workout];
}

class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError(this.message);

  @override
  List<Object> get props => [message];
}

class WorkoutHistoryLoaded extends WorkoutState {
  final List<Workout> workouts;

  const WorkoutHistoryLoaded(this.workouts);

  @override
  List<Object> get props => [workouts];
}

// ---------------------------------------------------------------------------
// NEW RUN-PHASE STATE MODEL (incremental adoption)
// ---------------------------------------------------------------------------
// These states will progressively replace the legacy generic "WorkoutInProgress"
// usage within the UI. For now we keep both to avoid breaking existing screens.
// The goal: express explicit phases (loading set, active set, rest, finishing)
// and remove UI-owned timers / flags.

/// Domain-level finish intent for the current interactive segment.
/// Mirrors the previous UI-only enum (FinishType) but moved to bloc layer.
enum RunFinishType { set, exercise, workout }

/// Marker mixin for run-phase states (a workout currently in an interactive flow).
mixin WorkoutRunPhase on WorkoutState {}

/// Emitted while preparing or awaiting data needed to enter a run phase.
class WorkoutRunLoading extends WorkoutState with WorkoutRunPhase {}

/// Active set phase: user is performing a set (timer counting up per set).
class WorkoutRunInSet extends WorkoutState with WorkoutRunPhase {
  final Workout workout; // full workout progression so far
  final CustomWorkout? workoutToFollow; // planned template (optional)
  final CustomWorkoutExercise currentExercise; // exercise being performed
  final int currentExerciseIdx; // index in planned list (if any)
  final int
  currentSetIdx; // zero-based index of next set to complete within exercise
  final List<WorkoutSet>
  completedSets; // sets already recorded for this exercise
  final Duration elapsed; // elapsed time for CURRENT set
  final RunFinishType finishType; // what finishing action will produce

  const WorkoutRunInSet({
    required this.workout,
    required this.workoutToFollow,
    required this.currentExercise,
    required this.currentExerciseIdx,
    required this.currentSetIdx,
    required this.completedSets,
    required this.elapsed,
    required this.finishType,
  });

  @override
  List<Object?> get props => [
    workout,
    workoutToFollow,
    currentExercise,
    currentExerciseIdx,
    currentSetIdx,
    completedSets,
    elapsed,
    finishType,
  ];
}

/// Rest phase between sets / exercises.
class WorkoutRunRest extends WorkoutState with WorkoutRunPhase {
  final Workout workout;
  final CustomWorkout? workoutToFollow;
  final CustomWorkoutExercise
  currentExercise; // exercise just completed (or mid-exercise rest)
  final int currentExerciseIdx;
  final int currentSetIdx; // next set index to start when rest ends
  final Duration remaining; // rest remaining
  final Duration total; // originally allocated rest
  final CustomWorkoutExercise? nextExercise; // null if workout end
  final double progress; // overall workout progress 0..1
  final List<CustomWorkoutExercise>
  upcomingReorderable; // reorderable tail slice
  final int reorderStartIndex; // global index at which reordering slice begins
  final bool isFinishing; // user triggered early finish & awaiting persistence

  const WorkoutRunRest({
    required this.workout,
    required this.workoutToFollow,
    required this.currentExercise,
    required this.currentExerciseIdx,
    required this.currentSetIdx,
    required this.remaining,
    required this.total,
    required this.nextExercise,
    required this.progress,
    required this.upcomingReorderable,
    required this.reorderStartIndex,
    required this.isFinishing,
  });

  @override
  List<Object?> get props => [
    workout,
    workoutToFollow,
    currentExercise,
    currentExerciseIdx,
    currentSetIdx,
    remaining,
    total,
    nextExercise,
    progress,
    upcomingReorderable,
    reorderStartIndex,
    isFinishing,
  ];
}

/// Emitted when finalization logic (upload/persist) is running after the user
/// elected to finish the workout (distinct from a set/exercise finish).
class WorkoutRunFinishing extends WorkoutState with WorkoutRunPhase {
  final Workout workout;
  const WorkoutRunFinishing(this.workout);

  @override
  List<Object?> get props => [workout];
}

// NOTE: We reuse existing WorkoutCompleted & WorkoutError for terminal states.
