import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/app_styles.dart';
import '../../models/predefined_workout.dart';

class PredefinedWorkoutBreakScreen extends StatefulWidget {
  final int restTime; // in seconds
  final PredefinedWorkoutExercise nextExercise;
  final int currentSetIndex;
  final int totalSets;
  final double workoutProgress;
  final VoidCallback onBreakComplete;

  const PredefinedWorkoutBreakScreen({
    super.key,
    required this.restTime,
    required this.nextExercise,
    required this.currentSetIndex,
    required this.totalSets,
    required this.workoutProgress,
    required this.onBreakComplete,
  });

  @override
  State<PredefinedWorkoutBreakScreen> createState() => _PredefinedWorkoutBreakScreenState();
}

class _PredefinedWorkoutBreakScreenState extends State<PredefinedWorkoutBreakScreen> {
  late int _remainingTime;
  late int _totalTime; // Track total time including added minutes
  Timer? _timer;

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
          _remainingTime--;
        } else {
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
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a), // Darker background for better contrast
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
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

              const SizedBox(height: 50),

              // Next exercise info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      'NEXT UP',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.nextExercise.name.replaceAll('_', ' ').toUpperCase(),
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
                      color: Colors.white.withOpacity(0.2),
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
                  Container(
                    width: 60,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: _addMinute,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      child: Text(
                            '+1\'',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
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
            ],
          ),
        ),
      ),
    );
  }
}
