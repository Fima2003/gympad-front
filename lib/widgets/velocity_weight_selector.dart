import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import 'number_picker.dart';

/// A velocity-aware weight selector using 0.5 kg steps and scroll physics that
/// scale user scrolling based on velocity. Does not replace existing selector yet.
class WeightSelectorVelocity extends StatefulWidget {
  final double initialWeight;
  final ValueChanged<double> onWeightChanged;
  final double minWeight;
  final double maxWeight;

  const WeightSelectorVelocity({
    super.key,
    required this.onWeightChanged,
    this.initialWeight = 15.0,
    this.minWeight = 0.5,
    this.maxWeight = 200.0,
  });

  @override
  State<WeightSelectorVelocity> createState() => _WeightSelectorVelocityState();
}

class _WeightSelectorVelocityState extends State<WeightSelectorVelocity> {
  // 0.5 kg per step
  static const double _stepKg = 0.5;
  late int _currentIndex; // 1-based index where 1 == minWeight

  int get _minIndex => 1;
  int get _maxIndex =>
      ((widget.maxWeight - widget.minWeight) / _stepKg).round() + 1;

  double get _currentWeight =>
      widget.minWeight + ((_currentIndex - 1) * _stepKg);

  @override
  void initState() {
    super.initState();
    final rawIndex =
        ((widget.initialWeight - widget.minWeight) / _stepKg).round() + 1;
    _currentIndex = rawIndex.clamp(_minIndex, _maxIndex);
  }

  void _onChanged(int value) {
    setState(() => _currentIndex = value);
    widget.onWeightChanged(_currentWeight);
  }

  @override
  Widget build(BuildContext context) {
    // One item is one 0.5kg step
    final itemWidth = 65.0;
    final visibleCount =
        ((MediaQuery.of(context).size.width / 85).floor() / 2).floor() * 2 + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Weight',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: NumberPicker(
            value: _currentIndex,
            minValue: _minIndex,
            maxValue: _maxIndex,
            axis: Axis.horizontal,
            itemHeight: 80,
            itemWidth: itemWidth,
            itemCount: visibleCount,
            step: 1,
            haptics: true,
            physics: _VelocityScaledFixedExtentPhysics(
              basePixelsPerStep: 20.0,
              // Velocity at which multiplier ~= 2x
              v0: 1200.0, // logical px / s
              maxMultiplier: 4.0,
            ),
            onChanged: _onChanged,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary, width: 2),
              color: AppColors.accent,
            ),
            textMapper: (numberText) {
              final int index = int.parse(numberText);
              final double weight = widget.minWeight + ((index - 1) * _stepKg);
              return weight.toStringAsFixed(1);
            },
            textStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            selectedTextStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// ScrollPhysics that scale the user offset and fling velocity based on how fast
/// the finger/scroll is moving; designed for fixed-extent lists (step=1).
class _VelocityScaledFixedExtentPhysics extends ScrollPhysics {
  final double basePixelsPerStep;
  final double v0; // velocity normalization base (px/s)
  final double maxMultiplier;

  const _VelocityScaledFixedExtentPhysics({
    ScrollPhysics? parent,
    required this.basePixelsPerStep,
    required this.v0,
    required this.maxMultiplier,
  }) : super(parent: parent);

  @override
  _VelocityScaledFixedExtentPhysics applyTo(ScrollPhysics? ancestor) {
    return _VelocityScaledFixedExtentPhysics(
      parent: buildParent(ancestor),
      basePixelsPerStep: basePixelsPerStep,
      v0: v0,
      maxMultiplier: maxMultiplier,
    );
  }

  double _multiplierForVelocity(double velocity) {
    final speed = velocity.abs();
    final norm = speed / v0;
    // Smooth curve 1..max
    final m = 1 + (maxMultiplier - 1) * (1 - math.exp(-norm));
    return m.clamp(1.0, maxMultiplier);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // When user drags, scale offset by a factor based on current activity velocity if available.
    // As a proxy, use recent offset magnitude: faster drags produce larger raw offsets per frame.
    // Keep it simple here: compute a heuristic velocity from offset per animation tick.
    final estVelocity = (offset / (1 / 60.0)); // px per second approx at 60fps
    final m = _multiplierForVelocity(estVelocity);
    return offset * m;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Inflate fling velocity so it travels further when fast.
    final m = _multiplierForVelocity(velocity);
    return super.createBallisticSimulation(position, velocity * m);
  }
}
