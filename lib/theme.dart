import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light Mode Colors
  static const Color primaryLight = Color(0xFF22c55e);
  static const Color secondaryLight = Color(0xFFFFFFFF);
  static const Color tertiaryLight = Color(0xFFFFFFFF);
  static const Color alternateLight = Color(0xFF217942);

  static const Color primaryTextLight = Color(0xFF333333);
  static const Color secondaryTextLight = Color(0xFF666666);
  static const Color primaryBackgroundLight = Color(0xFFFFFFFF);
  static const Color secondaryBackgroundLight = Color(0xFFF2F2F2);

  static const Color accent1Light = Color(0xFFFFD700);
  static const Color accent2Light = Color(0xFFFF6611);
  static const Color accent3Light = Color(0xFF4A90E2);
  static const Color accent4Light = Color(0xFFB19CD9);

  static const Color successLight = Color(0xFF77DD77);
  static const Color errorLight = Color(0xFFFF6347);
  static const Color warningLight = Color(0xFFFFA500);
  static const Color infoLight = Color(0xFF87CEEB);

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFF1E9D4D);
  static const Color secondaryDark = Color(0xFF333333);
  static const Color tertiaryDark = Color(0xFF333333);
  static const Color alternateDark = Color(0xFF219F32);

  static const Color primaryTextDark = Color(0xFFFFFFFF);
  static const Color secondaryTextDark = Color(0xFFCCCCCC);
  static const Color primaryBackgroundDark = Color(0xFF333333);
  static const Color secondaryBackgroundDark = Color(0xFF1A1A1A);

  static const Color accent1Dark = Color(0xFFFFD700);
  static const Color accent2Dark = Color(0xFFFF6611);
  static const Color accent3Dark = Color(0xFF4A90E2);
  static const Color accent4Dark = Color(0xFFB19CD9);

  static const Color successDark = Color(0xFF77DD77);
  static const Color errorDark = Color(0xFFFF6347);
  static const Color warningDark = Color(0xFFFFA500);
  static const Color infoDark = Color(0xFF87CEEB);
}

class AppTheme {
  static final TextTheme textThemeLight = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 64,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextLight,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 44,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextLight,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextLight,
    ),

    headlineLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextLight,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextLight,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextLight,
    ),

    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryTextLight,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextLight,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextLight,
    ),

    bodyLarge: GoogleFonts.inter(
      fontSize: 18,
      color: AppColors.secondaryTextLight,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      color: AppColors.secondaryTextLight,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.secondaryTextLight,
    ),

    labelLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryTextLight,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.primaryTextLight,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryTextLight,
    ),
  );

  static final TextTheme textThemeDark = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 64,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextDark,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 44,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextDark,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextDark,
    ),

    headlineLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextDark,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextDark,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextDark,
    ),

    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryTextDark,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextDark,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryTextDark,
    ),

    bodyLarge: GoogleFonts.inter(
      fontSize: 18,
      color: AppColors.secondaryTextDark,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      color: AppColors.secondaryTextDark,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.secondaryTextDark,
    ),

    labelLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryTextDark,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.primaryTextDark,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryTextDark,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.primaryBackgroundLight,
    textTheme: textThemeLight,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryLight,
      titleTextStyle: textThemeLight.titleLarge,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.secondaryTextLight,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.primaryBackgroundDark,
    textTheme: textThemeDark,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      titleTextStyle: textThemeDark.titleLarge,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.secondaryTextDark,
    ),
  );
}
