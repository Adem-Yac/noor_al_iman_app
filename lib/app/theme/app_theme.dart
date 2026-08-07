import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Color(0xFFF8FAFC),
      primaryContainer: AppColors.chipMint,
      onPrimaryContainer: AppColors.primarySoft,
      secondary: AppColors.secondary,
      onSecondary: Color(0xFFF8FAFC),
      secondaryContainer: Color(0xFFD1FAE5),
      onSecondaryContainer: Color(0xFF00311F),
      tertiary: Color(0xFF2B6954),
      onTertiary: Color(0xFFF8FAFC),
      error: AppColors.error,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.textMuted,
      outlineVariant: AppColors.deco,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: AppColors.darkOnSurface,
      inversePrimary: AppColors.darkPrimary,
      surfaceTint: AppColors.primary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      dividerColor: AppColors.deco,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 42,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: AppColors.primary,
          height: 1.15,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.4,
          color: AppColors.textMuted,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFFF8FAFC),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.deco;
        }),
      ),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: Color(0xFF80BEA6),
      secondary: AppColors.darkSecondary,
      onSecondary: Color(0xFF003824),
      secondaryContainer: Color(0xFF00A572),
      onSecondaryContainer: Color(0xFF00311F),
      tertiary: Color(0xFF45DFA4),
      onTertiary: Color(0xFF003825),
      tertiaryContainer: Color(0xFF004F35),
      onTertiaryContainer: Color(0xFF23CA90),
      error: AppColors.darkError,
      onError: Color(0xFF690005),
      errorContainer: AppColors.darkErrorContainer,
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFDAE2FD),
      onInverseSurface: Color(0xFF283044),
      inversePrimary: Color(0xFF2B6954),
      surfaceTint: AppColors.darkPrimary,
      surfaceContainerLowest: AppColors.darkSurfaceLowest,
      surfaceContainerLow: Color(0xFF131B2E),
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkSurfaceHigh,
      surfaceContainerHighest: AppColors.darkSurfaceHighest,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkOutlineVariant,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.darkOnSurface,
        displayColor: AppColors.darkOnSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkPrimaryContainer,
          foregroundColor: const Color(0xFFF8FAFC),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkOnPrimary;
          }
          return AppColors.darkOnSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkPrimary;
          }
          return AppColors.darkOutlineVariant;
        }),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurfaceHigh,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceHighest,
        contentTextStyle: TextStyle(color: AppColors.darkOnSurface),
      ),
    );
  }
}
