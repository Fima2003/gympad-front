import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/audio/audio_bloc.dart';
import '../../../blocs/data/data_bloc.dart';
import '../../../blocs/workout/workout_bloc.dart';
import '../../../models/custom_workout.dart';
import '../../well_done_workout_screen.dart';
import 'cworkout_break_view.dart';

class CWorkoutBreakManager extends StatefulWidget {
  const CWorkoutBreakManager({super.key});

  @override
  State<CWorkoutBreakManager> createState() => _CWorkoutBreakManagerState();
}

class _CWorkoutBreakManagerState extends State<CWorkoutBreakManager> {
  late int _remainingTime;
  late int _totalTime;
  Timer? _timer;
  bool _finishing = false;

  WorkoutInProgress get progressState {
    final s = context.read<WorkoutBloc>().state;
    if (s is! WorkoutInProgress) {
      throw StateError('Workout was not initialized properly');
    }
    if (s.workoutToFollow == null) {
      throw StateError('Workout state is not valid');
    }
    return s;
  }

  CustomWorkoutExercise? get nextExerciseMaybe {
    final exercises = progressState.workoutToFollow!.exercises;
    final nextIdx = progressState.currentExerciseIdx;
    if (nextIdx < exercises.length) {
      return exercises[nextIdx];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _remainingTime =
        progressState
            .workoutToFollow!
            .exercises[progressState.currentExerciseIdx]
            .restTime;
    _totalTime = _remainingTime;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingTime > 1) {
          final next = _remainingTime - 1;
          if (next <= 5 && next >= 1) {
            context.read<AudioBloc>().add(PlayTickSound());
          }
          _remainingTime = next;
        } else {
          context.read<AudioBloc>().add(PlayStartSound());
          _timer?.cancel();
          _handleBreakComplete();
        }
      });
    });
  }

  void _handleBreakComplete() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _skipBreak() {
    _timer?.cancel();
    _handleBreakComplete();
  }

  void _addThirtySeconds() {
    _timer?.cancel();
    setState(() {
      _remainingTime += 30;
      _totalTime += 30;
    });
    _startCountdown();
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Finish workout?'),
            content: const Text(
              'Are you sure you want to finish this workout now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed:
                    _finishing
                        ? null
                        : () {
                          Navigator.of(context).pop();
                          _finishWorkout();
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  void _finishWorkout() {
    if (_finishing) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    context.read<WorkoutBloc>().add(WorkoutFinished());
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = progressState.workoutToFollow!.exercises;
    final idx = progressState.currentExerciseIdx.clamp(0, exercises.length - 1);
    final previous = exercises.take(idx).toList();
    final future =
        idx + 1 < exercises.length
            ? exercises.sublist(idx + 1)
            : const <CustomWorkoutExercise>[];

    // Determine reorder window start index in full workout list.
    // If current exercise has not actually started (no sets recorded yet and we are at its index), include it in reorder window.
    final bool currentExerciseStarted = progressState.currentSetIdx > 0;
    // If currentExerciseStarted -> upcoming starts after current exercise; else include current exercise
    final reorderStartIndex = currentExerciseStarted ? idx + 1 : idx;
    final upcomingSlice = exercises.skip(reorderStartIndex).toList();

    void handleReorder(List<CustomWorkoutExercise> newOrder) {
      context.read<WorkoutBloc>().add(
            UpcomingExercisesReordered(
              reorderStartIndex,
              newOrder.map((e) => e.id).toList(),
            ),
          );
    }

    return BlocListener<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutCompleted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder:
                  (context) => WellDoneWorkoutScreen(workout: state.workout),
            ),
            (route) => route.isFirst,
          );
        }
      },
      child: CWorkoutBreakView(
        remainingTime: _remainingTime,
        totalTime: _totalTime,
        formatTime: _formatTime,
        onAddThirtySeconds: _addThirtySeconds,
        onSkip: _skipBreak,
        onFinishWorkout: _showFinishDialog,
        previousExercises: previous,
        futureExercises: future,
        currentSetIdx: progressState.currentSetIdx,
        currentExercise: exercises[progressState.currentExerciseIdx],
        progress: progressState.progress ?? 0,
        dataBloc: context.read<DataBloc>(),
        nextExercise: nextExerciseMaybe,
        isFinishing: _finishing,
  canReorder: upcomingSlice.length > 1,
  upcomingReorderable: upcomingSlice,
  onReorderUpcoming: handleReorder,
      ),
    );
  }
}
