import 'package:flutter/material.dart';

/// Palettes light / dark — Emerald Nocturne (DESIGN.md).
abstract final class AppColors {
  // ——— Light (jour) ———
  static const Color primary = Color(0xFF064E3B);
  static const Color primarySoft = Color(0xFF0B513D);
  static const Color accent = Color(0xFF2B6954);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0B1326);
  static const Color textSecondary = Color(0xFF404944);
  static const Color textMuted = Color(0xFF89938D);
  static const Color deco = Color(0xFFD5DBD8);
  static const Color navSelected = Color(0xFF064E3B);
  static const Color chipMint = Color(0xFFB0F0D6);
  static const Color tabInactive = Color(0xFFEEF1F0);
  static const Color secondary = Color(0xFF00A572);
  static const Color error = Color(0xFF93000A);

  // ——— Dark (Emerald Nocturne) ———
  static const Color darkBackground = Color(0xFF0B1326);
  static const Color darkSurfaceLowest = Color(0xFF060E20);
  static const Color darkSurface = Color(0xFF171F33);
  static const Color darkSurfaceHigh = Color(0xFF222A3D);
  static const Color darkSurfaceHighest = Color(0xFF2D3449);
  /// Accent vert (boutons / sélection) — pas pour le texte.
  static const Color darkPrimary = Color(0xFF95D3BA);
  static const Color darkPrimaryContainer = Color(0xFF064E3B);
  static const Color darkOnPrimary = Color(0xFF003829);
  static const Color darkSecondary = Color(0xFF4EDEA3);
  /// Texte principal dark → blanc (plus de vert clair / gris clair).
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFFF2F2F2);
  static const Color darkOutline = Color(0xFFE0E0E0);
  static const Color darkOutlineVariant = Color(0xFF404944);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkErrorContainer = Color(0xFF93000A);

  /// Couleurs adaptées au thème courant.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffoldOf(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color cardOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color textOf(BuildContext context) =>
      isDark(context) ? darkOnSurface : textPrimary;

  static Color mutedOf(BuildContext context) =>
      isDark(context) ? darkOnSurfaceVariant : textSecondary;

  static Color softOf(BuildContext context) =>
      isDark(context) ? darkOutline : textMuted;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkOutlineVariant : deco;

  /// Titres / labels : blanc en dark, vert en light.
  static Color primaryOf(BuildContext context) =>
      isDark(context) ? darkOnSurface : primary;

  /// Accent marque (icônes actives, chips sélectionnés, fills).
  static Color accentOf(BuildContext context) =>
      isDark(context) ? darkPrimary : primary;

  static Color chipOf(BuildContext context) =>
      isDark(context) ? darkPrimaryContainer : chipMint;

  static Color subtleOf(BuildContext context) =>
      isDark(context) ? darkSurfaceHighest : tabInactive;

  static Color onPrimaryOf(BuildContext context) =>
      isDark(context) ? darkOnPrimary : Colors.white;
}
