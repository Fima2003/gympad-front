import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/audio_service.dart';
import 'dart:async';
import '../../constants/app_styles.dart';
import '../../models/custom_workout.dart';
import '../../services/data_service.dart';
import '../../blocs/workout_bloc.dart';
import '../../services/global_timer_service.dart';
import '../well_done_workout_screen.dart';
import '../../widgets/exercise_chip.dart';

class PredefinedWorkoutBreakScreen extends StatefulWidget {
  final int restTime; // in seconds
  final CustomWorkoutExercise? nextExercise;
  final List<CustomWorkoutExercise> allExercises;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final int totalSets;
  final double workoutProgress;
  final VoidCallback onBreakComplete;

  const PredefinedWorkoutBreakScreen({
    super.key,
    required this.restTime,
    required this.nextExercise,
    required this.allExercises,
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.totalSets,
    required this.workoutProgress,
    required this.onBreakComplete,
  });

  @override
  State<PredefinedWorkoutBreakScreen> createState() =>
      _PredefinedWorkoutBreakScreenState();
}

class _PredefinedWorkoutBreakScreenState
    extends State<PredefinedWorkoutBreakScreen> {
  late int _remainingTime;
  late int _totalTime; // Track total time including added minutes
  Timer? _timer;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.restTime;
    _totalTime = widget.restTime; // Initially same as rest time

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 1) {
          final next = _remainingTime - 1;
          // Play a tick when 5 seconds or less remain (5,4,3,2,1)
          if (next <= 5 && next >= 1) {
            AudioService().playTick();
          }
          _remainingTime = next;
        } else {
          // Countdown finished: play start sound then complete break
          AudioService().playStart();
          _timer?.cancel();
          widget.onBreakComplete();
        }
      });
    });
  }

  void _skipBreak() {
    _timer?.cancel();
    widget.onBreakComplete();
  }

  void _addMinute() {
    // Cancel current timer
    _timer?.cancel();

    // Add 60 seconds to remaining time and total time
    setState(() {
      _remainingTime += 60;
      _totalTime += 60;
    });

    // Restart the countdown timer
    _startCountdown();
  }

  // Sound playback is handled via AudioService for easy future swaps

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
    GlobalTimerService().stop();
    context.read<WorkoutBloc>().add(ExerciseFinished());
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
    // Build previous/future lists for visual chips (current is represented by the Next box)
    final exercises = widget.allExercises;
    final idx = widget.currentExerciseIndex.clamp(0, exercises.length - 1);
    final previous = exercises.take(idx).toList();
    final future =
        idx + 1 < exercises.length
            ? exercises.sublist(idx + 1)
            : const <CustomWorkoutExercise>[];

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
      child: Scaffold(
        backgroundColor: const Color(
          0xFF1a1a1a,
        ), // Darker background for better contrast
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  // Finish flag button (was in AppBar)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      tooltip: 'Finish workout',
                      icon: const Icon(Icons.flag, color: Colors.white),
                      onPressed: _showFinishDialog,
                    ),
                  ),
                  // Main scrollable content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                  // Rest title
                  Text(
                    'REST TIME',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Countdown timer with circular progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: (_totalTime - _remainingTime) / _totalTime,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            _formatTime(_remainingTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'remaining',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Next exercise info (optional)
                  if (widget.nextExercise != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Explicit NEXT label
                          Text(
                            'NEXT:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (DataService()
                                        .getExercise(widget.nextExercise!.id)
                                        ?.name ??
                                    widget.nextExercise!.id)
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set ${widget.currentSetIndex + 1} of ${widget.totalSets}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Visual chips: previous (check), future (clock). Current is the Next box above.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (previous.isNotEmpty) ...[
                        _PredefinedExerciseChipsRow(
                          items: previous,
                          variant: ExerciseChipVariant.previous,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (future.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _PredefinedExerciseChipsRow(
                          items: future,
                          variant: ExerciseChipVariant.future,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Workout progress bar
                  Column(
                    children: [
                      Text(
                        'WORKOUT PROGRESS',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.workoutProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(widget.workoutProgress * 100).toInt()}% Complete',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // Action buttons
                  Row(
                    children: [
                      // Add minute button - circular design
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: OutlinedButton(
                          onPressed: _addMinute,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                          ),
                          child: Text(
                            '+1\'',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Skip break button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _skipBreak,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1a1a1a),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'SKIP BREAK',
                            style: AppTextStyles.button.copyWith(
                              color: const Color(0xFF1a1a1a),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PredefinedExerciseChipsRow extends StatelessWidget {
  final List<CustomWorkoutExercise> items;
  final ExerciseChipVariant variant;

  const _PredefinedExerciseChipsRow({
    required this.items,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            items.map((e) {
              final meta = DataService().getExercise(e.id);
              final name =
                  (meta?.name ?? e.id).replaceAll('_', ' ').toUpperCase();
              return ExerciseChip(
                title: name,
                setsCount: e.setsAmount,
                variant: variant,
              );
            }).toList(),
      ),
    );
  }
}
