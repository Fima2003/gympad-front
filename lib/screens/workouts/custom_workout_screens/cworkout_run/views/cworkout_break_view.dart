import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../blocs/data/data_bloc.dart';
import '../../../../../constants/app_styles.dart';
import '../../../../../models/custom_workout.dart';
import '../../../../../widgets/exercise_chip.dart';

class CWorkoutBreakView extends StatelessWidget {
  final int remainingTime;
  final int totalTime;
  final String Function(int seconds) formatTime;
  final VoidCallback onAddThirtySeconds;
  final VoidCallback onSkip;
  final VoidCallback onFinishWorkout;
  final List<CustomWorkoutExercise> previousExercises;
  final List<CustomWorkoutExercise> futureExercises;
  final int currentSetIdx;
  final CustomWorkoutExercise currentExercise;
  final double progress; // 0..1
  final DataBloc dataBloc;
  final CustomWorkoutExercise?
  nextExercise; // same as currentExercise? kept for parity
  final bool isFinishing;
  final bool canReorder;
  final List<CustomWorkoutExercise> upcomingReorderable; // subset to reorder
  final void Function(List<CustomWorkoutExercise>) onReorderUpcoming;

  const CWorkoutBreakView({
    super.key,
    required this.remainingTime,
    required this.totalTime,
    required this.formatTime,
    required this.onAddThirtySeconds,
    required this.onSkip,
    required this.onFinishWorkout,
    required this.previousExercises,
    required this.futureExercises,
    required this.currentSetIdx,
    required this.currentExercise,
    required this.progress,
    required this.dataBloc,
    required this.nextExercise,
    required this.isFinishing,
    required this.canReorder,
    required this.upcomingReorderable,
    required this.onReorderUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final timerSize = height < 700 ? 150.0 : 190.0;
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'REST TIME',
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
                  const SizedBox(height: 8),
                  // Timer & next side-by-side (responsive)
                  Flexible(
                    flex: 4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animated progress ring WITH time inside
                        _AnimatedProgressRing(
                          size: timerSize,
                          progress: (totalTime - remainingTime) / totalTime,
                          builder:
                              () => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatTime(remainingTime),
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
                        const SizedBox(width: 20),
                        // Next info card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'NEXT',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (canReorder)
                                      GestureDetector(
                                        onTap: () => _openReorderSheet(context),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.tune,
                                              size: 16,
                                              color: AppColors.accent,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Edit',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color: AppColors.accent,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _nextExerciseTitle(),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  () {
                                    // If we're between exercises (nextExercise differs from currentExercise), always show upcoming exercise set 1.
                                    if (nextExercise != null &&
                                        nextExercise!.id !=
                                            currentExercise.id) {
                                      return 'Set 1 of ${nextExercise!.setsAmount}';
                                    }
                                    return 'Set ${currentSetIdx + 1} of ${currentExercise.setsAmount}';
                                  }(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Completed exercises chips only
                  if (previousExercises.isNotEmpty)
                    SizedBox(
                      height: 60,
                      child: _PredefinedExerciseChipsRow(
                        items: previousExercises,
                        variant: ExerciseChipVariant.previous,
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Progress (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROGRESS',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.accent.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Actions
                  Row(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: onAddThirtySeconds,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              width: 2,
                              color: Colors.white,
                            ),
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
                          onPressed: onSkip,
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
                ],
              ),
              if (isFinishing) ...[
                const ModalBarrier(dismissible: false, color: Colors.black26),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _nextExerciseTitle() {
    if (nextExercise == null) return '---';
    final weight = nextExercise!.suggestedWeight;
    final dataState = dataBloc.state;
    String name;
    if (dataState is DataReady) {
      final ex = dataState.exercises[nextExercise!.id];
      name = (ex?.name ?? nextExercise!.id).toUpperCase();
    } else {
      name = nextExercise!.id.toUpperCase();
    }
    if (weight != null && weight > 0) {
      return '$name: ${weight}kg';
    }
    return name;
  }

  void _openReorderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Reorder Upcoming',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ReorderUpcomingRow(
                items: upcomingReorderable,
                dataBloc: dataBloc,
                onChanged: (list) {
                  onReorderUpcoming(list);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated circular progress ring that tween-animates between progress updates
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
                  backgroundColor: Colors.white.withOpacity(0.08),
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
            colors: [foregroundColor, foregroundColor.withOpacity(0.6)],
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
            items
                .map(
                  (e) => Builder(
                    builder: (context) {
                      final dataState = context.read<DataBloc>().state;
                      String name;
                      if (dataState is DataReady) {
                        final ex = dataState.exercises[e.id];
                        name =
                            (ex?.name ?? e.id)
                                .replaceAll('_', ' ')
                                .toUpperCase();
                      } else {
                        name = e.id.replaceAll('_', ' ').toUpperCase();
                      }
                      return ExerciseChip(
                        title: name,
                        setsCount: e.setsAmount,
                        variant: variant,
                      );
                    },
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _ReorderUpcomingRow extends StatefulWidget {
  final List<CustomWorkoutExercise> items;
  final DataBloc dataBloc;
  final void Function(List<CustomWorkoutExercise>) onChanged;
  const _ReorderUpcomingRow({
    required this.items,
    required this.dataBloc,
    required this.onChanged,
  });

  @override
  State<_ReorderUpcomingRow> createState() => _ReorderUpcomingRowState();
}

class _ReorderUpcomingRowState extends State<_ReorderUpcomingRow> {
  late List<CustomWorkoutExercise> _working;
  int? _draggingIndex;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollKey = GlobalKey();
  Offset? _lastGlobalDragPos;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _working = [...widget.items];
  }

  @override
  void didUpdateWidget(covariant _ReorderUpcomingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _working = [...widget.items];
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.swap_vert, color: Colors.white70, size: 18),
            const SizedBox(width: 4),
            Text(
              'Reorder upcoming exercises',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            ),
            const Spacer(),
            if (_draggingIndex != null)
              Text(
                'Drag to rearrange',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          key: _scrollKey,
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          child: Row(children: _buildDraggableRow()),
        ),
      ],
    );
  }

  List<Widget> _buildDraggableRow() {
    final widgets = <Widget>[];
    for (int i = 0; i < _working.length; i++) {
      widgets.add(_buildDropZone(i));
      widgets.add(_buildDraggableChip(i));
    }
    widgets.add(_buildDropZone(_working.length));
    return widgets;
  }

  Widget _buildDropZone(int index) {
    final isActive = _draggingIndex != null;
    return DragTarget<int>(
      onWillAccept:
          (from) => from != null && from != index && from != index - 1,
      onAccept: (from) {
        setState(() {
          final item = _working.removeAt(from);
          final insertIndex = from < index ? index - 1 : index;
          _working.insert(insertIndex, item);
          _draggingIndex = null;
        });
        // Immediately persist new order
        widget.onChanged(_working);
      },
      onLeave: (_) {},
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: highlight ? 20 : 12,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color:
                highlight
                    ? AppColors.accent.withOpacity(0.6)
                    : (isActive ? Colors.white24 : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildDraggableChip(int index) {
    final e = _working[index];
    final dataState = widget.dataBloc.state;
    String name;
    if (dataState is DataReady) {
      final ex = dataState.exercises[e.id];
      name = (ex?.name ?? e.id).replaceAll('_', ' ').toUpperCase();
    } else {
      name = e.id.replaceAll('_', ' ').toUpperCase();
    }
    final chip = ExerciseChip(
      title: name,
      setsCount: e.setsAmount,
      variant: ExerciseChipVariant.future,
    );
    return Draggable<int>(
      data: index,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => setState(() => _draggingIndex = index),
      onDragEnd: (_) {
        _autoScrollTimer?.cancel();
        setState(() => _draggingIndex = null);
      },
      onDragUpdate: (details) {
        _lastGlobalDragPos = details.globalPosition;
        _startAutoScrollIfNeeded();
      },
      feedback: Opacity(
        opacity: 0.9,
        child: Material(
          color: Colors.transparent,
          child: Transform.scale(scale: 1.05, child: chip),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }

  void _startAutoScrollIfNeeded() {
    if (_autoScrollTimer?.isActive == true) return;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (_lastGlobalDragPos == null) return;
      final box = _scrollKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final size = box.size;
      final pos = box.globalToLocal(_lastGlobalDragPos!);
      const edge = 56.0; // sensitivity zone
      const speed = 28.0; // px per tick
      double? delta;
      if (pos.dx < edge) {
        if (_scrollController.position.pixels > 0) {
          delta = -speed;
        }
      } else if (pos.dx > size.width - edge) {
        if (_scrollController.position.pixels <
            _scrollController.position.maxScrollExtent) {
          delta = speed;
        }
      }
      if (delta != null) {
        final target = (_scrollController.position.pixels + delta).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(target);
      }
    });
  }
}
