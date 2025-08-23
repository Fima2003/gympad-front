import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

enum ExerciseChipVariant { previous, current, future }

class ExerciseChip extends StatefulWidget {
  final String title;
  final int setsCount; // performed or planned depending on context
  final ExerciseChipVariant variant;
  final EdgeInsetsGeometry margin;

  const ExerciseChip({
    super.key,
    required this.title,
    required this.setsCount,
    required this.variant,
    this.margin = const EdgeInsets.only(right: 10),
  });

  @override
  State<ExerciseChip> createState() => _ExerciseChipState();
}

class _ExerciseChipState extends State<ExerciseChip>
    with TickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isCurrent = widget.variant == ExerciseChipVariant.current;
    final isPrevious = widget.variant == ExerciseChipVariant.previous;
    final isFuture = widget.variant == ExerciseChipVariant.future;

    final border =
        isCurrent
            ? AppColors.accent
            : Colors.white.withValues(alpha: isPrevious ? 0.25 : 0.15);
    final bg =
        isCurrent
            ? AppColors.accent.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06);
    final opacity = isPrevious ? 0.6 : (isFuture ? 0.8 : 1.0);
    final height = isCurrent ? 64.0 : 52.0;
    final padding = EdgeInsets.symmetric(
      horizontal: isCurrent ? 16 : 14,
      vertical: 10,
    );
    final Widget icon =
        isCurrent
            ? Icon(Icons.play_circle_fill, color: AppColors.accent, size: 20)
            : isPrevious
            ? const Icon(Icons.check_circle, color: Colors.white70, size: 18)
            : const Icon(Icons.schedule, color: Colors.white60, size: 18);

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          margin: widget.margin,
          padding: padding,
          height: height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: isCurrent ? 2 : 1),
            boxShadow:
                isCurrent
                    ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                alignment: Alignment.centerLeft,
                child:
                    _expanded
                        ? Row(
                          children: [
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.fitness_center,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.setsCount} sets',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
