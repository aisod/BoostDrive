import 'package:flutter/material.dart';

/// Light/dark tokens aligned with Stitch `professional_light` and `design_system`.
class DashboardPalette {
  final bool isDark;

  const DashboardPalette({required this.isDark});

  factory DashboardPalette.of(BuildContext context) {
    return DashboardPalette(isDark: Theme.of(context).brightness == Brightness.dark);
  }

  // Canvas
  Color get background => isDark ? const Color(0xFF09151B) : const Color(0xFFF9F9F9);
  Color get onBackground => isDark ? const Color(0xFFD8E4EE) : const Color(0xFF1A1C1C);

  // Surfaces
  Color get surface => isDark ? const Color(0xFF121D24) : const Color(0xFFF9F9F9);
  Color get surfaceDim => isDark ? const Color(0xFF09151B) : const Color(0xFFDADADA);
  Color get surfaceContainerLowest => isDark ? const Color(0xFF050F16) : Colors.white;
  Color get surfaceContainerLow => isDark ? const Color(0xFF121D24) : const Color(0xFFF3F3F3);
  Color get surfaceContainer => isDark ? const Color(0xFF162128) : const Color(0xFFEEEEEE);
  Color get surfaceContainerHigh => isDark ? const Color(0xFF202B33) : const Color(0xFFE8E8E8);
  Color get surfaceContainerHighest => isDark ? const Color(0xFF2B363E) : const Color(0xFFE2E2E2);
  Color get surfaceVariant => isDark ? const Color(0xFF2B363E) : const Color(0xFFE2E2E2);

  // Legacy aliases used by existing dashboard widgets
  Color get card => surfaceContainerLowest;
  Color get cardBorder => isDark ? const Color(0xFF5A4138) : const Color(0xFFE8E8E8);

  Color get title => onBackground;
  Color get body => isDark ? const Color(0xFFE3BFB2) : const Color(0xFF515F78);
  Color get muted => isDark ? const Color(0xFFAA8A7E) : const Color(0xFF8F7066);
  Color get onSurfaceVariant => isDark ? const Color(0xFFE3BFB2) : const Color(0xFF5A4138);

  Color get outline => isDark ? const Color(0xFFAA8A7E) : const Color(0xFF8F7066);
  Color get outlineVariant => isDark ? const Color(0xFF5A4138) : const Color(0xFFE3BFB2);

  // Brand
  Color get primary => isDark ? const Color(0xFFF95E14) : const Color(0xFFA43700);
  Color get onPrimary => Colors.white;
  Color get primaryContainer => isDark ? const Color(0xFFF95E14) : const Color(0xFFCD4700);
  Color get primaryBright => isDark ? const Color(0xFFFFB59A) : const Color(0xFFCD4700);
  Color get primaryFixed => isDark ? const Color(0xFF802A00) : const Color(0xFFFFDBCF);
  Color get primaryFixedDim => isDark ? const Color(0xFFFFB59A) : const Color(0xFFFFB59A);
  Color get onPrimaryFixed => isDark ? const Color(0xFF4F1700) : const Color(0xFF380D00);
  Color get onPrimaryFixedVariant => isDark ? const Color(0xFFFFB59A) : const Color(0xFF802A00);

  Color get secondary => isDark ? const Color(0xFFFFB77D) : const Color(0xFF515F78);
  Color get secondaryContainer => isDark ? const Color(0xFF202B33) : const Color(0xFFD2E0FE);
  Color get onSecondaryContainer => isDark ? const Color(0xFFE3BFB2) : const Color(0xFF55637D);

  Color get tertiary => isDark ? const Color(0xFFC6C6C7) : const Color(0xFF4A5F69);
  Color get tertiaryFixed => isDark ? const Color(0xFF354A53) : const Color(0xFFCFE6F2);
  Color get onTertiaryFixed => isDark ? const Color(0xFFD8E4EE) : const Color(0xFF071E27);

  Color get navBar => isDark ? const Color(0xFFCD4700) : const Color(0xFFA43700);
  Color get onNav => Colors.white;

  Color get error => isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  Color get success => isDark ? const Color(0xFF7DD99A) : const Color(0xFF1B7A3D);
  Color get successSurface => isDark ? const Color(0xFF1A3D28) : const Color(0xFFE8F5E9);

  double get radiusDefault => 16;
  double get radiusLg => 24;
  double get radiusPill => 999;

  List<BoxShadow> get cardShadowLow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          blurRadius: isDark ? 16 : 12,
          offset: const Offset(0, 4),
        ),
      ];

  List<BoxShadow> get cardShadowHigh => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
          blurRadius: isDark ? 24 : 24,
          offset: const Offset(0, 8),
        ),
      ];
}
