import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/data/data_bloc.dart';
import '../../../constants/app_styles.dart';
import '../../../models/custom_workout.dart';
import '../../../widgets/exercise_chip.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: (totalTime - remainingTime) / totalTime,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accent,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              formatTime(remainingTime),
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
                            _nextExerciseTitle(),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set ${currentSetIdx + 1} of ${currentExercise.setsAmount}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (previousExercises.isNotEmpty) ...[
                          _PredefinedExerciseChipsRow(
                            items: previousExercises,
                            variant: ExerciseChipVariant.previous,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (futureExercises.isNotEmpty && !canReorder) ...[
                          const SizedBox(height: 12),
                          _PredefinedExerciseChipsRow(
                            items: futureExercises,
                            variant: ExerciseChipVariant.future,
                          ),
                        ] else if (canReorder) ...[
                          const SizedBox(height: 12),
                          _ReorderUpcomingRow(
                            items: upcomingReorderable,
                            dataBloc: dataBloc,
                            onChanged: onReorderUpcoming,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 30),
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
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(progress * 100).toInt()}% Complete',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onSkip,
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
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    tooltip: 'Finish workout',
                    icon: const Icon(Icons.flag, color: Colors.white),
                    onPressed: onFinishWorkout,
                  ),
                ),
                if (isFinishing) ...[
                  const ModalBarrier(dismissible: false, color: Colors.black26),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
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
