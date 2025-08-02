import 'package:flutter/material.dart';
import 'package:gympad/widgets/number_picker.dart';
import '../constants/app_styles.dart';

class RepsSelector extends StatefulWidget {
  final Function(int) onRepsSelected;

  const RepsSelector({Key? key, required this.onRepsSelected})
    : super(key: key);

  @override
  State<RepsSelector> createState() => _RepsSelectorState();
}

class _RepsSelectorState extends State<RepsSelector> {
  int _reps = 8; // Default to 8 reps

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many reps, champ?', style: AppTextStyles.titleMedium),
            const SizedBox(height: 32),
            NumberPicker(
              value: _reps,
              minValue: 1,
              maxValue: 100,
              step: 1,
              itemHeight: 80,
              itemWidth: 80,
              itemCount: 3,
              axis: Axis.horizontal,
              onChanged: (value) => setState(() => _reps = value),
              selectedTextStyle: AppTextStyles.titleMedium.copyWith(
                fontSize: 28,
                color: AppColors.primary,
              ),
              textStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary.withOpacity(0.5),
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRepsSelected(_reps);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Save',
                  style: AppTextStyles.button.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
