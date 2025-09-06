import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gympad/blocs/workout/workout_bloc.dart';
import 'package:gympad/screens/workouts/custom_workout_screens/cworkout_run/views/cworkout_set_view.dart';

import '../../../../blocs/data/data_bloc.dart';
import '../../../../models/custom_workout.dart';
import 'views/cworkout_break_view.dart';

class CWorkoutRunScreen extends StatefulWidget {
  const CWorkoutRunScreen({super.key});

  @override
  State<CWorkoutRunScreen> createState() => _CWorkoutRunScreenState();
}

class _CWorkoutRunScreenState extends State<CWorkoutRunScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutCompleted) {
          context.pushReplacement('/workout/well-done', extra: state.workout);
        } else if (state is WorkoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, s) {
        // New run-phase state
        if (s is WorkoutRunInSet) {
          final currentExercise = s.currentExercise;
          // Resolve display name from DataBloc (fallback to id if not found)
          final dataBloc = context.read<DataBloc>();
          final exData = dataBloc.state.exerciseById(currentExercise.id);
          final displayName = exData?.name ?? currentExercise.id;
          return Stack(
            children: [
              CWorkoutRunView(
                workoutTitle: s.workoutToFollow?.name ?? 'Workout',
                exerciseName: displayName,
                totalSets: currentExercise.setsAmount,
                initialWeight: currentExercise.suggestedWeight ?? 0,
                suggestedReps: currentExercise.suggestedReps ?? 0,
                completedSets: s.completedSets,
                onFinish:
                    (w, r, d) => context.read<WorkoutBloc>().add(
                      RunFinishCurrent(weight: w, reps: r, duration: d),
                    ),
                finishType: () {
                  switch (s.finishType) {
                    case RunFinishType.set:
                      return FinishType.set;
                    case RunFinishType.exercise:
                      return FinishType.exercise;
                    case RunFinishType.workout:
                      return FinishType.workout;
                  }
                }(),
                elapsed: s.elapsed,
                isRunning: true,
              ),
            ],
          );
        }
        if (s is WorkoutRunRest) {
          // Derive previous / future exercises from plan if present
          final plan = s.workoutToFollow;
          List<CustomWorkoutExercise> previous = [];
          List<CustomWorkoutExercise> future = [];
          if (plan != null && plan.exercises.isNotEmpty) {
            final idx = s.currentExerciseIdx.clamp(
              0,
              plan.exercises.length - 1,
            );
            previous = plan.exercises.take(idx).toList();
            future =
                idx + 1 < plan.exercises.length
                    ? plan.exercises.sublist(idx + 1)
                    : const <CustomWorkoutExercise>[];
          }

          String formatTime(int secs) {
            final m = secs ~/ 60;
            final rs = secs % 60;
            return '${m.toString().padLeft(2, '0')}:${rs.toString().padLeft(2, '0')}';
          }

          return CWorkoutBreakView(
            remainingTime: s.remaining.inSeconds,
            totalTime: s.total.inSeconds,
            formatTime: formatTime,
            onAddThirtySeconds:
                () => context.read<WorkoutBloc>().add(const RunExtendRest()),
            onSkip: () => context.read<WorkoutBloc>().add(const RunSkipRest()),
            onFinishWorkout: () async {
              if (context.read<WorkoutBloc>().state is WorkoutRunFinishing)
                return;
              final confirmed = await showDialog<bool>(
                context: context,
                barrierDismissible: true,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Finish workout early?'),
                    content: const Text(
                      'Are you sure you want to end the workout now? Progress for the remaining sets will be lost.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => ctx.pop(false),
                        child: const Text('No'),
                      ),
                      FilledButton(
                        onPressed: () => ctx.pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );
              if (confirmed == true && mounted) {
                context.read<WorkoutBloc>().add(const RunFinishEarly());
              }
            },
            previousExercises: previous,
            futureExercises: future,
            currentSetIdx: s.currentSetIdx,
            currentExercise: s.currentExercise,
            progress: s.progress,
            dataBloc: context.read<DataBloc>(),
            nextExercise: s.nextExercise,
            isFinishing: s.isFinishing,
            canReorder: s.upcomingReorderable.length > 1,
            upcomingReorderable: s.upcomingReorderable,
            onReorderUpcoming:
                (list) => context.read<WorkoutBloc>().add(
                  UpcomingExercisesReordered(
                    s.reorderStartIndex,
                    list.map((e) => e.id).toList(),
                  ),
                ),
          );
        }
        if (s is WorkoutRunFinishing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
