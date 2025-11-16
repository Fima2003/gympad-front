import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../constants/app_styles.dart';
import '../../../../../models/workout_exercise.dart';
import '../../../../../widgets/exercise_chip.dart';

/// Free workout rest-phase view (presentation only).
///
/// Expects parent orchestration (future FreeWorkoutRunScreen) to:
///  - Provide timing (remaining & total seconds)
///  - Provide current exercise display name and previous exercises list
///  - Manage finishing / skipping / extending logic via callbacks that dispatch bloc events
class FreeWorkoutBreakView extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final String
  exerciseName; // exercise just completed OR currently ongoing between sets
  final int
  completedSetsForExercise; // number of sets already done for this exercise
  final List<WorkoutExercise>
  previousExercises; // earlier exercises this session
  final bool isFinishing;
  final double?
  progress; // 0..1 optional overall progress (can be null in free mode)

  final VoidCallback onNewSet; // start next set of same exercise immediately
  final VoidCallback onNewExercise; // open selection view
  final VoidCallback onFinishWorkout; // confirm & finish early
  final VoidCallback onSkipRest; // skip remaining rest
  final VoidCallback onAddThirtySeconds; // extend rest by +30s

  const FreeWorkoutBreakView({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.exerciseName,
    required this.completedSetsForExercise,
    required this.previousExercises,
    required this.isFinishing,
    this.progress,
    required this.onNewSet,
    required this.onNewExercise,
    required this.onFinishWorkout,
    required this.onSkipRest,
    required this.onAddThirtySeconds,
  });

  String _format(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ringSize = MediaQuery.of(context).size.height < 700 ? 160.0 : 200.0;
    final height = MediaQuery.of(context).size.height;
    final timerSize = height < 700 ? 150.0 : 190.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'REST',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Finish workout',
                    icon: const Icon(Icons.flag, color: Colors.white),
                    onPressed: onFinishWorkout,
                  ),
                ],
              ),
              const SizedBox(height: 36),
              // Timer ring
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _AnimatedProgressRing(
                      size: timerSize,
                      progress:
                          (totalSeconds - remainingSeconds) / totalSeconds,
                      builder:
                          () => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _format(remainingSeconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'remaining',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Current exercise panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      exerciseName.replaceAll('_', ' ').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SETS COMPLETED: $completedSetsForExercise',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (previousExercises.isNotEmpty) ...[
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PREVIOUS',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: previousExercises.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      final e = previousExercises[i];
                      return ExerciseChip(
                        title: e.name.replaceAll('_', ' ').toUpperCase(),
                        setsCount: e.sets.length,
                        variant: ExerciseChipVariant.previous,
                      );
                    },
                  ),
                ),
              ],
              const Spacer(),
              // Action buttons
              if (!isFinishing) ...[
                TextButton(
                  onPressed: onNewExercise,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: const Text('New Exercise'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: onAddThirtySeconds,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(width: 2, color: Colors.white),
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        child: Text(
                          '+30\'\'',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onSkipRest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1a1a1a),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'SKIP',
                          style: AppTextStyles.button.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: CircularProgressIndicator(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgressRing extends StatefulWidget {
  final double size;
  final double progress; // 0..1
  final Widget Function() builder; // inner content builder

  const _AnimatedProgressRing({
    required this.size,
    required this.progress,
    required this.builder,
  });

  @override
  State<_AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<_AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _to = widget.progress.clamp(0, 1);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.progress - widget.progress).abs() > 0.0001) {
      _from = _to;
      _to = widget.progress.clamp(0, 1);
      final delta = (_to - _from).abs();
      final ms = (delta * 600).clamp(120, 900).toInt();
      _controller
        ..duration = Duration(milliseconds: ms)
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final value = lerpDouble(_from, _to, _animation.value)!;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size.square(widget.size),
                painter: _RingPainter(
                  progress: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: AppColors.accent,
                ),
              ),
              // Inner content
              widget.builder(),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color backgroundColor;
  final Color foregroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
    double strokeWidth = 6,
  }) : strokeWidth = strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    final bgPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = backgroundColor;
    final fgPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: 2 * math.pi,
            colors: [foregroundColor, foregroundColor.withValues(alpha: 0.6)],
          ).createShader(rect);

    // Draw background full circle
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      0,
      2 * math.pi,
      false,
      bgPaint,
    );

    // Draw foreground arc
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      startAngle,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.foregroundColor != foregroundColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
