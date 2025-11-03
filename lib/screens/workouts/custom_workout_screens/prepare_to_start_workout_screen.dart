import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../blocs/analytics/analytics_bloc.dart';
import '../../../blocs/user_settings/user_settings_bloc.dart';
import '../../../blocs/workout/workout_bloc.dart';
import '../../../constants/app_styles.dart';
import '../../../models/custom_workout.dart';
import '../../../blocs/data/data_bloc.dart';
import '../../../blocs/audio/audio_bloc.dart';
import '../../../utils/get_weight.dart';

class PrepareToStartWorkoutScreen extends StatefulWidget {
  final CustomWorkout workout;

  const PrepareToStartWorkoutScreen({super.key, required this.workout});

  @override
  State<PrepareToStartWorkoutScreen> createState() =>
      _PrepareToStartWorkoutScreenState();
}

class _PrepareToStartWorkoutScreenState
    extends State<PrepareToStartWorkoutScreen>
    with SingleTickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown == 3) {
          context.read<WorkoutBloc>().add(
            WorkoutStarted(
              widget.workout.workoutType,
              workoutToFollow: widget.workout,
            ),
          );
        }
        if (_countdown > 1) {
          _countdown--;
          // Play tick for the last 2 seconds (when showing 2 and 1)
          if (_countdown <= 3 && _countdown > 1) {
            context.read<AudioBloc>().add(PlayTickSound());
          }
          _animationController
            ..reset()
            ..forward();
        } else {
          // Final start beep
          context.read<AudioBloc>().add(PlayStartSound());
          _timer?.cancel();
          _navigateToWorkout();
        }
      });
    });

    _animationController.forward();
  }

  void _navigateToWorkout() {
    if (mounted) {
      context.read<AnalyticsBloc>().add(AStartedWorkout());
      context.pushReplacement('/workout/custom/run');
    }
  }

  void _cancelWorkout() {
    BlocProvider.of<WorkoutBloc>(context).add(WorkoutCancelled());
    _timer?.cancel();
    context.pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Workout name
            Text(
              widget.workout.name,
              style: AppTextStyles.titleLarge.copyWith(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // First exercise name
            Text(
              'Starting with:',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            BlocBuilder<UserSettingsBloc, UserSettingsState>(
              builder: (context, state) {
                return Text(
                  widget.workout.exercises.isNotEmpty
                      ? (() {
                        final dataState =
                            BlocProvider.of<DataBloc>(context).state;
                        final ex =
                            (dataState is DataReady)
                                ? dataState.exercises[widget
                                    .workout
                                    .exercises
                                    .first
                                    .id]
                                : null;
                        final weight =
                            (dataState is DataReady)
                                ? widget.workout.exercises.first.suggestedWeight
                                : null;
                        final showWeight = (weight != null && weight > 0);
                        final name =
                            (ex?.name ?? widget.workout.exercises.first.id)
                                .replaceAll('_', ' ')
                                .toUpperCase();
                        return showWeight
                            ? "$name: ${state is! UserSettingsLoaded ? "$weight kg" : getWeightString(weight, state.weightUnit)}"
                            : name;
                      })()
                      : 'Exercise',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),

            const SizedBox(height: 60),

            // Countdown timer
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 60),

            // Get ready text
            Text(
              _countdown > 1 ? 'Get Ready!' : "Let's Go!",
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 80),

            // Cancel button
            TextButton(
              onPressed: _cancelWorkout,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
