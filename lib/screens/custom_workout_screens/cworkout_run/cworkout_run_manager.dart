import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/blocs/workout/workout_bloc.dart';
import 'package:gympad/screens/custom_workout_screens/cworkout_run/cworkout_run_view.dart';

import '../../../blocs/data/data_bloc.dart';
import '../../../constants/app_styles.dart';
import '../../../models/custom_workout.dart';
import '../../../models/exercise.dart';
import '../../well_done_workout_screen.dart';
import '../cworkout_break/cworkout_break_manager.dart';

class CWorkoutRunManager extends StatefulWidget {
  const CWorkoutRunManager({super.key});

  @override
  State<CWorkoutRunManager> createState() => _CWorkoutRunManagerState();
}

class _CWorkoutRunManagerState extends State<CWorkoutRunManager> {
  final ValueNotifier<Duration> setDurationNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<bool> isTimerRunningNotifier = ValueNotifier(false);
  Timer? _setTimer;

  String get workoutTitle => state.workoutToFollow!.name;
  String get exerciseName {
    if (state.workout.exercises.isNotEmpty) {
      return state.workout.exercises.last.name;
    }
    return state.workoutToFollow!.exercises[state.currentExerciseIdx].id;
  }

  bool _isFinishing = false;

  WorkoutInProgress get state {
    final currentState = BlocProvider.of<WorkoutBloc>(context).state;
    if (currentState is WorkoutInProgress &&
        currentState.workoutToFollow != null) {
      return currentState;
    }
    print(currentState);
    throw Exception('Invalid state');
  }

  CustomWorkoutExercise get currentExercise {
    return state.workoutToFollow!.exercises[state.currentExerciseIdx];
  }

  FinishType get finishType {
    if (state.currentSetIdx < currentExercise.setsAmount - 1) {
      return FinishType.set;
    }
    if (state.currentExerciseIdx <
        state.workoutToFollow!.exercises.length - 1) {
      return FinishType.exercise;
    }
    return FinishType.workout;
  }

  @override
  void initState() {
    tryStartExercise();
    super.initState();
    // Start timer automatically on first load
    startSetTimer();
  }

  void startSetTimer() {
    _setTimer?.cancel();
    _setTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setDurationNotifier.value = Duration(
        seconds: setDurationNotifier.value.inSeconds + 1,
      );
    });
    isTimerRunningNotifier.value = true;
  }

  void stopSetTimer() {
    _setTimer?.cancel();
    isTimerRunningNotifier.value = false;
  }

  void resetSetTimer() {
    _setTimer?.cancel();
    setDurationNotifier.value = Duration.zero;
    isTimerRunningNotifier.value = false;
  }

  void tryStartExercise() {
    if (state.currentSetIdx != 0) {
      return;
    }
    final Exercise? exercise = BlocProvider.of<DataBloc>(
      context,
    ).state.exerciseById(currentExercise.id);
    if (exercise == null) return;
    BlocProvider.of<WorkoutBloc>(context).add(
      ExerciseAdded(
        exerciseId: exercise.id,
        name: exercise.name,
        muscleGroup: exercise.muscleGroup,
      ),
    );
  }

  void handleSetFinish(
    double selectedWeight,
    int selectedReps,
    Duration duration,
  ) {
    context.read<WorkoutBloc>().add(
      SetAdded(reps: selectedReps, weight: selectedWeight, duration: duration),
    );
    goToBreak();
  }

  void handleExerciseFinish(
    double selectedWeight,
    int selectedReps,
    Duration duration,
  ) {
    context.read<WorkoutBloc>().add(
      ExerciseFinished(
        reps: selectedReps,
        weight: selectedWeight,
        duration: duration,
      ),
    );
    goToBreak();
  }

  void handleWorkoutFinish(
    double selectedWeight,
    int selectedReps,
    Duration duration,
  ) {
    setState(() {
      _isFinishing = true;
    });
    context.read<WorkoutBloc>().add(
      WorkoutFinished(
        reps: selectedReps,
        weight: selectedWeight,
        duration: duration,
      ),
    );
  }

  void goToBreak() {
    stopSetTimer();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CWorkoutBreakManager(),
      ),
    ).then((_) {
      // When break completes (popped), restart timers and continue
      if (!mounted) return;
      resetSetTimer();
      startSetTimer();
      tryStartExercise();
    });
  }

  void handleFinish(
    double selectedWeight,
    int selectedReps,
    Duration duration,
  ) {
    print(finishType);
    switch (finishType) {
      case FinishType.set:
        handleSetFinish(selectedWeight, selectedReps, duration);
        break;
      case FinishType.exercise:
        handleExerciseFinish(selectedWeight, selectedReps, duration);
        break;
      case FinishType.workout:
        handleWorkoutFinish(selectedWeight, selectedReps, duration);
        break;
    }
  }

  @override
  void dispose() {
    _setTimer?.cancel();
    setDurationNotifier.dispose();
    isTimerRunningNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => WellDoneWorkoutScreen(workout: state.workout),
            ),
          );
        } else if (state is WorkoutError) {
          if (mounted) {
            setState(() {
              _isFinishing = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is! WorkoutInProgress) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Stack(
          children: [
            CWorkoutRunView(
              workoutTitle: workoutTitle,
              exerciseName: exerciseName,
              totalSets: currentExercise.setsAmount,
              initialWeight: currentExercise.suggestedWeight!,
              suggestedReps: currentExercise.suggestedReps!,
              completedSets:
                  this.state.workout.exercises.isNotEmpty
                      ? this.state.workout.exercises.last.sets
                      : [],
              onFinish: handleFinish,
              finishType: finishType,
              setDurationNotifier: setDurationNotifier,
              isTimerRunningNotifier: isTimerRunningNotifier,
              onStartSet: startSetTimer,
              onStopSet: stopSetTimer,
              onResetSet: resetSetTimer,
            ),
            if (_isFinishing) ...[
              const ModalBarrier(dismissible: false, color: Colors.black26),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Finishing workout…',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
