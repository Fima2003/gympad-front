import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

class WorkoutTimer extends StatefulWidget {
  final bool isRunning;
  final Function(Duration) onTimeChanged;

  const WorkoutTimer({
    super.key,
    required this.isRunning,
    required this.onTimeChanged,
  });

  @override
  State<WorkoutTimer> createState() => WorkoutTimerState();
}

class WorkoutTimerState extends State<WorkoutTimer> {
  Duration _currentTime = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(WorkoutTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (widget.isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _currentTime = Duration(seconds: _currentTime.inSeconds + 1);
        });
        widget.onTimeChanged(_currentTime);
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void reset() {
    setState(() {
      _currentTime = Duration.zero;
    });
    widget.onTimeChanged(_currentTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Text(
        _formatTime(_currentTime),
        style: AppTextStyles.titleLarge.copyWith(
          fontSize: 36,
          color: AppColors.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
