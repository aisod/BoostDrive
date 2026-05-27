import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_palette.dart';

/// Montserrat text styles from Stitch professional light / dark mockups.
class DashboardTypography {
  DashboardTypography._();

  static TextStyle displayLg(DashboardPalette p) => GoogleFonts.montserrat(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -0.02 * 48,
        color: p.title,
      );

  static TextStyle headlineLg(DashboardPalette p) => GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.01 * 32,
        color: p.title,
      );

  static TextStyle headlineMd(DashboardPalette p) => GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: p.title,
      );

  static TextStyle bodyLg(DashboardPalette p) => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        color: p.body,
      );

  static TextStyle bodyMd(DashboardPalette p) => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: p.body,
      );

  static TextStyle bodySm(DashboardPalette p) => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: p.body,
      );

  static TextStyle labelLg(DashboardPalette p) => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: p.title,
      );

  static TextStyle labelMd(DashboardPalette p) => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: p.muted,
      );

  static TextStyle sectionLabel(DashboardPalette p) => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: p.onSurfaceVariant,
      );
}
