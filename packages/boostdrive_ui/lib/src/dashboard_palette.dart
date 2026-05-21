import 'package:flutter/material.dart';

/// Light/dark tokens for customer, seller, and messages dashboards (Stitch / professional light).
class DashboardPalette {
  final bool isDark;

  const DashboardPalette({required this.isDark});

  factory DashboardPalette.of(BuildContext context) {
    return DashboardPalette(isDark: Theme.of(context).brightness == Brightness.dark);
  }

  Color get background => isDark ? const Color(0xFF09151B) : const Color(0xFFF9F9F9);
  Color get surface => isDark ? const Color(0xFF121D24) : const Color(0xFFF3F3F3);
  Color get card => isDark ? const Color(0xFF162128) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF5A4138) : const Color(0xFFE8E8E8);
  Color get title => isDark ? const Color(0xFFD8E4EE) : const Color(0xFF1A1C1C);
  Color get body => isDark ? const Color(0xFFE3BFB2) : const Color(0xFF515F78);
  Color get muted => isDark ? const Color(0xFFAA8A7E) : const Color(0xFF8F7066);
  Color get primary => isDark ? const Color(0xFFF95E14) : const Color(0xFFA43700);
  Color get primaryBright => isDark ? const Color(0xFFFFB59A) : const Color(0xFFCD4700);
  Color get primaryFixed => isDark ? const Color(0xFF802A00) : const Color(0xFFFFDBCF);
  Color get secondaryContainer => isDark ? const Color(0xFF202B33) : const Color(0xFFD2E0FE);
  Color get tertiaryFixed => isDark ? const Color(0xFF354A53) : const Color(0xFFCFE6F2);
  Color get navBar => isDark ? const Color(0xFFCD4700) : const Color(0xFFA43700);
  Color get onNav => Colors.white;
  Color get error => isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);

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
