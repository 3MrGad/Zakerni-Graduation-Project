import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const sage    = Color(0xFF6B9080);
  static const sageLt  = Color(0xFFA4C3B2);
  static const cream   = Color(0xFFF6F0E8);
  static const warm    = Color(0xFFE8D5B7);
  static const amber   = Color(0xFFD4A853);
  static const coral   = Color(0xFFE07A5F);
  static const navy    = Color(0xFF2D3561);
  static const charcoal= Color(0xFF3D405B);
  static const white   = Color(0xFFFEFCF9);
  static const shadow  = Color(0x1F2D3561);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: ColorScheme.light(
      primary:   AppColors.sage,
      secondary: AppColors.amber,
      error:     AppColors.coral,
      surface:   AppColors.white,
    ),
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.lora(
        fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.navy,
      ),
      displayMedium: GoogleFonts.lora(
        fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.navy,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.charcoal,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.charcoal,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      shadowColor: AppColors.shadow,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.navy),
      titleTextStyle: GoogleFonts.lora(
        fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.navy,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.warm, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.warm, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sage, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}