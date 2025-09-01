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
                        if (futureExercises.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _PredefinedExerciseChipsRow(
                            items: futureExercises,
                            variant: ExerciseChipVariant.future,
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
