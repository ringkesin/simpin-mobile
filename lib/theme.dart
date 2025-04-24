import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- AppColors (tetap sama) ---
class AppColors {
  // ... (kode AppColors Anda) ...
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

// --- AppTheme ---
class AppTheme {
  // --- TextThemes (tetap sama) ---
  static final TextTheme textThemeLight = TextTheme(
    // ... (kode textThemeLight Anda) ...
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
    // ... (kode textThemeDark Anda) ...
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

  // --- ThemeData Definitions ---
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light, // Tentukan brightness
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.primaryBackgroundLight,
    colorScheme: ColorScheme.light(
      // Definisikan colorScheme
      primary: AppColors.primaryLight,
      secondary: AppColors.alternateLight, // Atau warna sekunder lain
      surface: AppColors.primaryBackgroundLight, // Warna permukaan utama
      background: AppColors.primaryBackgroundLight, // Warna background
      error: AppColors.errorLight,
      onPrimary: Colors.white, // Teks di atas primary
      onSecondary: Colors.white, // Teks di atas secondary
      onSurface: AppColors.primaryTextLight, // Teks di atas surface
      onBackground: AppColors.primaryTextLight, // Teks di atas background
      onError: Colors.white, // Teks di atas error
      primaryContainer: AppColors.primaryLight.withOpacity(
        0.1,
      ), // Contoh warna container
      secondaryContainer: AppColors.alternateLight.withOpacity(
        0.1,
      ), // Contoh warna container
    ),
    textTheme: textThemeLight,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white, // Warna ikon dan teks di app bar
      titleTextStyle: textThemeLight.titleLarge?.copyWith(color: Colors.white),
      elevation: 1, // Sedikit shadow di appbar
    ),
    // Hapus bottomNavigationBarTheme jika tidak digunakan lagi
    // bottomNavigationBarTheme: BottomNavigationBarThemeData(...),

    // --- TAMBAHKAN INI: NavigationBarThemeData ---
    navigationBarTheme: NavigationBarThemeData(
      height: 65, // Tinggi default bisa diatur di sini
      backgroundColor:
          AppColors.secondaryLight, // Background default NavBar (putih)
      indicatorColor: AppColors.primaryLight.withOpacity(
        0.15,
      ), // Warna indicator
      surfaceTintColor: Colors.transparent, // Hilangkan efek tint
      elevation: 0, // Elevation dihandle container pembungkus
      iconTheme: MaterialStateProperty.resolveWith((states) {
        // Atur warna ikon default dan terpilih
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.primaryLight, size: 26);
        }
        return const IconThemeData(
          color: AppColors.secondaryTextLight,
          size: 24,
        );
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        // Atur style label default dan terpilih
        final style =
            textThemeLight.labelSmall ?? const TextStyle(fontSize: 12);
        if (states.contains(MaterialState.selected)) {
          return style.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.bold,
          );
        }
        return style.copyWith(color: AppColors.secondaryTextLight);
      }),
      labelBehavior:
          NavigationDestinationLabelBehavior
              .alwaysShow, // Sesuaikan default label behavior
    ),
    // --- AKHIR TAMBAHAN ---

    // Tambahkan theme lain jika perlu (ElevatedButton, TextField, dll)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: textThemeLight.labelLarge?.copyWith(color: Colors.white),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      // Default style untuk TextField
      filled: true,
      fillColor: AppColors.secondaryBackgroundLight,
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300.withOpacity(0.5),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      labelStyle: textThemeLight.bodyMedium?.copyWith(
        color: AppColors.secondaryTextLight,
      ),
      hintStyle: textThemeLight.bodyMedium?.copyWith(
        color: AppColors.secondaryTextLight.withOpacity(0.7),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark, // Tentukan brightness
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.primaryBackgroundDark,
    colorScheme: ColorScheme.dark(
      // Definisikan colorScheme dark
      primary: AppColors.primaryDark,
      secondary: AppColors.alternateDark,
      surface:
          AppColors
              .secondaryBackgroundDark, // Ganti surface ke warna yg lebih cocok
      background: AppColors.primaryBackgroundDark,
      error: AppColors.errorDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.primaryTextDark,
      onBackground: AppColors.primaryTextDark,
      onError: Colors.white,
      primaryContainer: AppColors.primaryDark.withOpacity(0.15),
      secondaryContainer: AppColors.alternateDark.withOpacity(0.1),
    ),
    textTheme: textThemeDark,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.secondaryDark, // Ganti warna app bar dark
      foregroundColor: Colors.white,
      titleTextStyle: textThemeDark.titleLarge?.copyWith(color: Colors.white),
      elevation: 0, // Hilangkan shadow di dark mode
    ),
    // Hapus bottomNavigationBarTheme jika tidak digunakan lagi

    // --- TAMBAHKAN INI: NavigationBarThemeData (Dark) ---
    navigationBarTheme: NavigationBarThemeData(
      height: 60,
      backgroundColor: AppColors.secondaryDark, // Background NavBar (gelap)
      indicatorColor: AppColors.primaryDark.withOpacity(
        0.2,
      ), // Indikator lebih gelap
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(
            color: AppColors.primaryDark,
            size: 26,
          ); // Warna primary dark
        }
        return const IconThemeData(
          color: AppColors.secondaryTextDark,
          size: 24,
        ); // Warna teks sekunder dark
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        final style = textThemeDark.labelSmall ?? const TextStyle(fontSize: 12);
        if (states.contains(MaterialState.selected)) {
          return style.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          );
        }
        return style.copyWith(color: AppColors.secondaryTextDark);
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    // --- AKHIR TAMBAHAN (Dark) ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: textThemeDark.labelLarge?.copyWith(color: Colors.white),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.secondaryBackgroundDark, // Warna isian dark
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade700,
          width: 1,
        ), // Border dark
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primaryDark,
          width: 1.5,
        ), // Border fokus dark
      ),
      labelStyle: textThemeDark.bodyMedium?.copyWith(
        color: AppColors.secondaryTextDark,
      ),
      hintStyle: textThemeDark.bodyMedium?.copyWith(
        color: AppColors.secondaryTextDark.withOpacity(0.7),
      ),
    ),
  );
}
