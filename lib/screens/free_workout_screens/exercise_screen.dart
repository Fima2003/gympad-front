import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_styles.dart';
import '../../models/gym.dart';
import '../../models/exercise.dart';
import '../../models/workout_set.dart';
import '../../blocs/workout/workout_bloc.dart';
import '../../services/workout_service.dart';
import '../../models/workout.dart';
import '../../widgets/velocity_weight_selector.dart';
import '../../widgets/reps_selector.dart';
import 'select_exercise_screen.dart';
import 'free_workout_break_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final Gym? gym;
  final Exercise exercise;
  final bool isPartOfWorkout;

  const ExerciseScreen({
    super.key,
    this.gym,
    required this.exercise,
    this.isPartOfWorkout = false,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  double _selectedWeight = 15.0;
  bool _isAwaitingReps = false;
  bool _breakScreenPushed = false;

  void _startSet(BuildContext context) {
    if (!widget.isPartOfWorkout) return;
    final bloc = context.read<WorkoutBloc>();
    final st = bloc.state;
    final workoutStarted =
        st is WorkoutInProgress ||
        st is WorkoutRunInSet ||
        st is WorkoutRunRest;
    if (!workoutStarted) {
      bloc.add(WorkoutStarted(WorkoutType.free));
      // ExerciseAdded dispatched after start to create initial exercise; RunEnterSet will follow.
      bloc.add(
        ExerciseAdded(
          exerciseId: widget.exercise.id,
          name: widget.exercise.name,
          muscleGroup: widget.exercise.muscleGroup,
        ),
      );
      return; // UI will rebuild into running state when RunInSet arrives.
    }
    // Workout started: ensure this exercise is last (current) so a new set can be added.
    if (st is WorkoutRunInSet ||
        st is WorkoutRunRest ||
        st is WorkoutInProgress) {
      Workout currentWorkout =
          (st is WorkoutRunInSet)
              ? st.workout
              : (st is WorkoutRunRest)
              ? st.workout
              : (st as WorkoutInProgress).workout;
      final existingIndex = currentWorkout.exercises.indexWhere(
        (e) => e.exerciseId == widget.exercise.id,
      );
      if (existingIndex == -1) {
        // Not present -> add new exercise then wait for RunEnterSet triggered by add
        bloc.add(
          ExerciseAdded(
            exerciseId: widget.exercise.id,
            name: widget.exercise.name,
            muscleGroup: widget.exercise.muscleGroup,
          ),
        );
      } else if (existingIndex != currentWorkout.exercises.length - 1) {
        // Present but not last -> re-add (service moves to last) then force enter set
        bloc.add(
          ExerciseAdded(
            exerciseId: widget.exercise.id,
            name: widget.exercise.name,
            muscleGroup: widget.exercise.muscleGroup,
          ),
        );
        // After reordering, explicitly enter set (if currently resting skip rest first).
        if (st is WorkoutRunRest) {
          bloc.add(const RunSkipRest());
        } else {
          bloc.add(const RunEnterSet());
        }
      } else {
        // Already current exercise. If resting, skip rest to start new set.
        if (st is WorkoutRunRest) {
          bloc.add(const RunSkipRest());
        } else if (st is WorkoutInProgress) {
          bloc.add(const RunEnterSet());
        }
      }
    }
  }

  void _stopSet(BuildContext context) {
    _showRepsSelector(context);
  }

  void _showRepsSelector(BuildContext context) {
    // Pause timer while selecting reps
    setState(() {
      _isAwaitingReps = true;
    });

    showDialog<int>(
      context: context,
      barrierDismissible: true, // allow tapping outside to go back
      builder: (context) => const RepsSelector(),
    ).then((reps) {
      // If user tapped outside or pressed back, reps will be null -> resume timer
      if (!mounted) return;
      if (reps == null) {
        if (!mounted) return;
        setState(() => _isAwaitingReps = false);
      } else {
        _saveSet(context, reps);
      }
    });
  }

  void _saveSet(BuildContext context, int reps) {
    // Use bloc elapsed time for current set duration.
    final st = context.read<WorkoutBloc>().state;
    Duration elapsed = Duration.zero;
    if (st is WorkoutRunInSet) elapsed = st.elapsed;
    setState(() => _isAwaitingReps = false);
    if (!widget.isPartOfWorkout) return; // standalone case (not migrated yet)
    context.read<WorkoutBloc>().add(
      RunFinishCurrent(weight: _selectedWeight, reps: reps, duration: elapsed),
    );
  }

  void _newExercise() {
    // Navigate to exercise selection, defaulting to current muscle group
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SelectExerciseScreen(
              selectedMuscleGroup: widget.exercise.muscleGroup,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 280.0;

    return BlocConsumer<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutRunInSet) {
          // Reset guard when a new set phase begins (new rest can push again later)
          _breakScreenPushed = false;
        } else if (state is WorkoutRunRest && widget.isPartOfWorkout) {
          final lastExercise =
              state.workout.exercises.isNotEmpty
                  ? state.workout.exercises.last.exerciseId
                  : null;
          final atRestStart =
              state.remaining ==
              state.total; // only first emission of rest phase
          if (lastExercise == widget.exercise.id &&
              atRestStart &&
              !_breakScreenPushed) {
            _breakScreenPushed = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => FreeWorkoutBreakScreen(
                        currentExercise: widget.exercise,
                        isPartOfWorkout: widget.isPartOfWorkout,
                        completedSets: const [],
                        onNewSet: () {},
                        onNewExercise: _newExercise,
                      ),
                ),
              );
            });
          }
        }
      },
      builder: (context, state) {
        // Determine if current exercise has an active set
        Duration elapsed = Duration.zero;
        List<WorkoutSet> completedSets = [];
        bool running = false;
        if (state is WorkoutRunInSet && widget.isPartOfWorkout) {
          final last =
              state.workout.exercises.isNotEmpty
                  ? state.workout.exercises.last
                  : null;
          if (last != null && last.exerciseId == widget.exercise.id) {
            running = true;
            elapsed = state.elapsed;
            completedSets = List.of(last.sets);
          }
        } else if ((state is WorkoutRunRest || state is WorkoutInProgress) &&
            widget.isPartOfWorkout) {
          // Always pull sets for this exercise even if not last (for revisit case)
          Workout workout =
              (state is WorkoutRunRest)
                  ? state.workout
                  : (state is WorkoutInProgress)
                  ? state.workout
                  : (state as WorkoutRunInSet).workout; // fallback not hit
          final match =
              workout.exercises
                  .where((e) => e.exerciseId == widget.exercise.id)
                  .toList();
          if (match.isNotEmpty) {
            completedSets = List.of(match.last.sets);
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.gym?.name ?? 'Workout',
                  style: AppTextStyles.appBarTitle,
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Exercise name
                  Text(
                    widget.exercise.name.replaceAll('_', ' ').toUpperCase(),
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Set info (no total in free mode)
                  Text(
                    'Set ${completedSets.length + ((running || _isAwaitingReps) ? 1 : 0)}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Timer display (pill)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color:
                          running
                              ? AppColors.accent
                              : AppColors.accent.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Weight selector (velocity-aware, 0.5kg steps)
                  Center(
                    child: WeightSelectorVelocity(
                      initialWeight: _selectedWeight,
                      onWeightChanged: (weight) {
                        setState(() {
                          _selectedWeight = weight;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Completed sets list (styled similar to custom)
                  if (completedSets.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completed Sets',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...completedSets.map(
                            (set) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Set ${set.setNumber}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${set.reps} reps × ${set.weight}kg',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${set.time.inMinutes}:${(set.time.inSeconds % 60).toString().padLeft(2, '0')}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Spacer(),

                  // Action button
                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            _isAwaitingReps
                                ? null
                                : (running
                                    ? () => _stopSet(context)
                                    : () => _startSet(context)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              running ? AppColors.accent : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          running ? 'Stop Set' : 'Start Set',
                          style: AppTextStyles.button.copyWith(
                            color:
                                running ? AppColors.primary : AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ); // Scaffold
      },
    ); // BlocConsumer
  }
}
