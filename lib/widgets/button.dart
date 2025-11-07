import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

/// A reusable elevated button component with consistent styling.
///
/// Provides two variants: primary (dark background) and accent (light background).
/// Handles full-width layout and custom text styling.
class GymPadButton extends StatelessWidget {
  /// Button text label
  final String label;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Button variant: 'primary' (dark) or 'accent' (light)
  final String variant;

  /// Optional custom icon to display before text
  final IconData? icon;

  /// Whether to expand button to full width
  final bool fullWidth;

  /// Custom text style (overrides variant defaults)
  final TextStyle? customTextStyle;

  /// Custom button padding (defaults to symmetric vertical 20)
  final EdgeInsets? customPadding;

  const GymPadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = 'primary',
    this.icon,
    this.fullWidth = false,
    this.customTextStyle,
    this.customPadding,
  }) : assert(
         variant == 'primary' || variant == 'accent',
         'variant must be "primary" or "accent"',
       );

  @override
  Widget build(BuildContext context) {
    // Determine colors based on variant
    final (backgroundColor, foregroundColor) =
        variant == 'primary'
            ? (AppColors.primary, AppColors.white)
            : (AppColors.accent, AppColors.primary);

    // Default text style based on variant
    final textStyle =
        customTextStyle ??
        AppTextStyles.button.copyWith(
          color: foregroundColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        );

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: customPadding ?? const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child:
          icon != null
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: customTextStyle != null ? customTextStyle!.color : foregroundColor),
                  const SizedBox(width: 8),
                  Text(label, style: textStyle),
                ],
              )
              : Text(label, style: textStyle),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
