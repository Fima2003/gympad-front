import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/app_styles.dart';
import '../../services/api/models/workout_models.dart';
import 'personal_workouts_run_screen.dart';
import '../../services/data_service.dart';

class PersonalPrepareToStartScreen extends StatefulWidget {
  final PersonalWorkoutResponse workout;

  const PersonalPrepareToStartScreen({super.key, required this.workout});

  @override
  State<PersonalPrepareToStartScreen> createState() =>
      _PersonalPrepareToStartScreenState();
}

class _PersonalPrepareToStartScreenState
    extends State<PersonalPrepareToStartScreen>
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
        if (_countdown > 1) {
          _countdown--;
          _animationController.reset();
          _animationController.forward();
        } else {
          _timer?.cancel();
          _navigateToWorkout();
        }
      });
    });

    _animationController.forward();
  }

  void _navigateToWorkout() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => PersonalWorkoutsRunScreen(workout: widget.workout),
        ),
      );
    }
  }

  void _cancelWorkout() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final first =
        widget.workout.exercises.isNotEmpty
            ? widget.workout.exercises.first
            : null;
    final firstName =
        first == null
            ? 'Exercise'
            : (DataService().getExercise(first.exerciseId)?.name ?? first.name)
                .replaceAll('_', ' ')
                .toUpperCase();

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
            Text(
              'Starting with:',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              firstName,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
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
