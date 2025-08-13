import 'package:flutter/material.dart';
import 'package:gympad/widgets/number_picker.dart';
import '../constants/app_styles.dart';

class WeightSelector extends StatefulWidget {
  final double initialWeight;
  final Function(double) onWeightChanged;

  const WeightSelector({
    super.key,
    this.initialWeight = 15.0,
    required this.onWeightChanged,
  });

  @override
  State<WeightSelector> createState() => _WeightSelectorState();
}

class _WeightSelectorState extends State<WeightSelector> {
  late int _currentWeightInt; // NumberPicker works with int, so we'll convert
  final double _increment = 2.5;
  final double _minWeight = 2.5;
  final double _maxWeight = 200.0;

  @override
  void initState() {
    super.initState();
    // Convert double weight to int index (2.5kg = 1, 5.0kg = 2, etc.)
    _currentWeightInt =
        ((widget.initialWeight - _minWeight) / _increment).round() + 1;
  }

  double get _currentWeight =>
      _minWeight + ((_currentWeightInt - 1) * _increment);

  int get _minValue => 1;
  int get _maxValue => ((_maxWeight - _minWeight) / _increment).round() + 1;

  void _onWeightChanged(int value) {
    setState(() {
      _currentWeightInt = value;
    });
    widget.onWeightChanged(_currentWeight);
  }

  @override
  Widget build(BuildContext context) {
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

        // NumberPicker with custom styling
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
            value: _currentWeightInt,
            minValue: _minValue,
            maxValue: _maxValue,
            axis: Axis.horizontal,
            itemHeight: 80,
            itemWidth: 65,
            itemCount: ((MediaQuery.of(context).size.width / 85).floor() / 2).floor() * 2 + 1,
            step: 1,
            haptics: true,
            onChanged: _onWeightChanged,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary, width: 2),
              color: AppColors.accent,
            ),
            textMapper: (numberText) {
              final int index = int.parse(numberText);
              final double weight = _minWeight + ((index - 1) * _increment);
              return weight.toString();
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

        const SizedBox(height: 12),
      ],
    );
  }
}
