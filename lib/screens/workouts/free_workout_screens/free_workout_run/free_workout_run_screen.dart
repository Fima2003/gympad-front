import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/workout/workout_bloc.dart';
import '../../../../blocs/data/data_bloc.dart';
import '../../../../constants/app_styles.dart';
import '../../../../models/exercise.dart';
import '../../../../models/workout_exercise.dart';
import 'views/free_workout_selection_view.dart';
import 'views/free_workout_set_view.dart';
import 'views/free_workout_break_view.dart';
import '../../../well_done_workout_screen.dart';

/// Orchestrates the free workout run-phase using the new bloc run states.
/// Single route that conditionally shows one of: selection, set, rest.
class FreeWorkoutRunScreen extends StatefulWidget {
  const FreeWorkoutRunScreen({super.key});

  @override
  State<FreeWorkoutRunScreen> createState() => _FreeWorkoutRunScreenState();
}

enum _FreeRunUIMode { selecting, running }

class _FreeWorkoutRunScreenState extends State<FreeWorkoutRunScreen> {
  _FreeRunUIMode _mode = _FreeRunUIMode.selecting; // start at selection

  @override
  void initState() {
    super.initState();
    // If already mid workout (set/rest), open directly in running mode.
    final st = context.read<WorkoutBloc>().state;
    if (st is WorkoutRunInSet || st is WorkoutRunRest || st is WorkoutRunFinishing) {
      _mode = _FreeRunUIMode.running;
    }
  }

  void _enterSelection() {
    final bloc = context.read<WorkoutBloc>();
    final st = bloc.state;
    // If we're resting, pause the rest timer.
    if (st is WorkoutRunRest) {
      bloc.add(const RunPauseRest());
    }
    setState(() => _mode = _FreeRunUIMode.selecting);
  }

  void _focusExercise(Exercise ex) {
    context.read<WorkoutBloc>().add(
          FreeWorkoutFocusExercise(
            exerciseId: ex.id,
            name: ex.name,
            muscleGroup: ex.muscleGroup,
          ),
        );
    // Screen will switch to running once we get a RunInSet state.
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutRunInSet) {
          // Any active set means we're running (exit selection mode)
            if (_mode != _FreeRunUIMode.running) {
              setState(() => _mode = _FreeRunUIMode.running);
            }
        }
        if (state is WorkoutRunRest && _mode == _FreeRunUIMode.running) {
          // remain running UI (rest view) unless user explicitly enters selection
        }
        if (state is WorkoutCompleted) {
          // Navigate to well done screen (replace current) like custom workout flow.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => WellDoneWorkoutScreen(workout: state.workout),
            ),
          );
        }
      },
      builder: (context, state) {
        // Determine which visual to show based on state + _mode
        if (_mode == _FreeRunUIMode.selecting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text('Select Exercise', style: AppTextStyles.appBarTitle),
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: Icon(Icons.close, color: AppColors.primary),
                onPressed: () {
                  final st = context.read<WorkoutBloc>().state;
                  final hasActive = st is WorkoutRunInSet || st is WorkoutRunRest;
                  // If a workout is active, just return to the running view instead of leaving the screen.
                  if (hasActive) {
                    // If we were resting and paused, resume the timer when returning.
                    if (st is WorkoutRunRest) {
                      context.read<WorkoutBloc>().add(const RunResumeRest());
                    }
                    if (mounted) setState(() => _mode = _FreeRunUIMode.running);
                  } else {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ),
            body: FreeWorkoutSelectionView(
              onExerciseChosen: _focusExercise,
              onExit: () {
                final st = context.read<WorkoutBloc>().state;
                if (st is WorkoutRunRest) {
                  context.read<WorkoutBloc>().add(const RunResumeRest());
                  if (mounted) setState(() => _mode = _FreeRunUIMode.running);
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          );
        }

        // Running mode: show set or rest or finishing spinner.
        if (state is WorkoutRunInSet) {
          // Derive exercise display name for free mode:
          final dataBloc = context.read<DataBloc>();
          final dataState = dataBloc.state;
          final exerciseId = state.currentExercise.id;
          String displayName = exerciseId;
          if (dataState is DataReady) {
            displayName = dataState.exercises[exerciseId]?.name ?? exerciseId;
          }

          final completedSets = state.completedSets;
          final lastWeight = completedSets.isNotEmpty ? completedSets.last.weight : 0.0;

          return FreeWorkoutSetView(
            exerciseName: displayName,
            completedSets: completedSets,
            elapsed: state.elapsed,
            initialWeight: lastWeight,
            isRunning: true,
            suggestedReps: state.currentExercise.suggestedReps,
            onFinish: (w, r, d) {
              context.read<WorkoutBloc>().add(
                    RunFinishCurrent(weight: w, reps: r, duration: d),
                  );
            },
          );
        }

        if (state is WorkoutRunRest) {
          // Build previous + current details from workout
          final workout = state.workout;
          final all = workout.exercises;
          List<WorkoutExercise> previous = [];
          WorkoutExercise? current; // last exercise in list
          if (all.isNotEmpty) {
            current = all.last;
            previous = all.length > 1 ? all.sublist(0, all.length - 1) : const [];
          }
          final setsCount = current?.sets.length ?? 0;
          final exerciseName = current?.name ?? state.currentExercise.id;

          return FreeWorkoutBreakView(
            remainingSeconds: state.remaining.inSeconds,
            totalSeconds: state.total.inSeconds,
            exerciseName: exerciseName,
            completedSetsForExercise: setsCount,
            previousExercises: previous,
            isFinishing: state.isFinishing,
            progress: state.progress, // note: may show 0 for free mode
            onNewSet: () => context.read<WorkoutBloc>().add(const RunSkipRest()),
            onNewExercise: _enterSelection,
            onFinishWorkout: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Finish workout?'),
                  content: const Text('Are you sure you want to finish now?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('No'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                context.read<WorkoutBloc>().add(const RunFinishEarly());
              }
            },
            onSkipRest: () => context.read<WorkoutBloc>().add(const RunSkipRest()),
            onAddThirtySeconds: () => context.read<WorkoutBloc>().add(const RunExtendRest()),
          );
        }

        if (state is WorkoutRunFinishing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Fallback: no workout yet => selection
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Select Exercise', style: AppTextStyles.appBarTitle),
            backgroundColor: AppColors.background,
          ),
          body: FreeWorkoutSelectionView(
            onExerciseChosen: _focusExercise,
          ),
        );
      },
    );
  }
}
