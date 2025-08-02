import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF0B4650);
  static const Color accent = Color(0xFFE6FF2B);
  static const Color background = Color(0xFFF9F7F2);
  static const Color textSecondary = Color(0xFF898A8D);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}

class AppTextStyles {
  static TextStyle get titleLarge => GoogleFonts.bebasNeue(
    fontSize: 32,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.italic,
    color: AppColors.primary,
  );

  static TextStyle get titleMedium => GoogleFonts.bebasNeue(
    fontSize: 24,
    fontWeight: FontWeight.normal,
    color: AppColors.primary,
  );

  static TextStyle get titleSmall => GoogleFonts.bebasNeue(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: AppColors.primary,
  );

  static TextStyle get bodyLarge => GoogleFonts.kanit(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );

  static TextStyle get bodyMedium => GoogleFonts.kanit(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );

  static TextStyle get bodySmall => GoogleFonts.kanit(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle get button => GoogleFonts.kanit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static TextStyle get appBarTitle => GoogleFonts.kanit(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
}
