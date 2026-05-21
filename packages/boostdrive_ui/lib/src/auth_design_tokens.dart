import 'package:flutter/material.dart';

/// Light/dark tokens from the BoostDrive auth design system (Stitch exports).
class AuthDesignTokens {
  final bool isDark;

  const AuthDesignTokens({required this.isDark});

  factory AuthDesignTokens.of(BuildContext context) {
    return AuthDesignTokens(isDark: Theme.of(context).brightness == Brightness.dark);
  }

  Color get background => isDark ? const Color(0xFF09151B) : const Color(0xFFF9F9F9);
  Color get surface => isDark ? const Color(0xFF09151B) : const Color(0xFFF9F9F9);
  Color get surfaceContainerLow => isDark ? const Color(0xFF121D24) : const Color(0xFFF3F3F3);
  Color get surfaceContainer => isDark ? const Color(0xFF162128) : const Color(0xFFEEEEEE);
  Color get surfaceContainerHighest => isDark ? const Color(0xFF2B363E) : const Color(0xFFE2E2E2);
  Color get onSurface => isDark ? const Color(0xFFD8E4EE) : const Color(0xFF1A1C1C);
  Color get onBackground => isDark ? const Color(0xFFD8E4EE) : const Color(0xFF1A1C1C);
  Color get onSurfaceVariant => isDark ? const Color(0xFFE3BFB2) : const Color(0xFF5A4138);
  Color get outlineVariant => isDark ? const Color(0xFF5A4138) : const Color(0xFFE3BFB2);
  Color get primary => isDark ? const Color(0xFFFFB59A) : const Color(0xFFA43700);
  Color get primaryContainer => isDark ? const Color(0xFFF95E14) : const Color(0xFFCD4700);
  Color get onPrimaryContainer => isDark ? const Color(0xFF4F1700) : const Color(0xFFFFFBFF);
  Color get primaryFixedDim => const Color(0xFFFFB59A);
  Color get error => isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  Color get errorContainer => isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6);

  static const String loginHeroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDTMdfEC-znt_TqfyIFBYpiU5xdTh3luo0bbCwUDt7s0PDphw2pPzu0WrABYy7hAoKMrE3qaUk5jje0Vz5QMCr48Dv2pDTIwqPDL-4_o1nuJcUg8BcljtUgN_quEmo6IkfrLTDHMgf-koKAXOgr8nusomtOLC0Y-T7TE2sgsZia61l9Y_ThD3Mf89z95AZrHX5ZOISYybdPuxRBhJTOl6ahgPSzWNmi0NfP0wvXhiaTxe8yDMXnLr9TFkMrpxqfU51Y0igaNL4ASxs';

  static const String signUpHeroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD-oWCxnjLbj2koYnLzxts6k6Ewnze-x4aJTsrxRK7ivtE_ZuPcgdZ9Wxz3EOSaSNAjNxxYhBIA5lIg25yUuoEI3HPEQAa0KRQcNIrB55Y1n-1Fpq08yiwwMxWyH7Cxs4L3b50_bmMFeviS1lIyjgyfo-NhPzU4sDFQ71Jf4edvRpNIcbZ7wY3DNgRpNrLkoP_FDjASSExiXzQF9pajxOSsV5Zp3vmE3OAsHrmdQ7_vm7ed5q5lCOSezHlkNfLV7RiDwMjD6lS6IDA';

  static const String otpHeroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB2MtZ5SsTBBnsTuSWrzGqTNmJMHzI2GvvxNBEKllFvPs1kCurRQpR7ETs_RGduZ-WRE5CC85iTx-GgEGHBjF6V1jfnexiN9qDRNOvCJosoZU_27l6O559Umoa5KpuBrGS4gyIkOOOoClW880xm1YsuO4X0svsd1b21xsqGHszpVcUwd5FSnf-ewCbtFBJdVNlO2RLQC7T_cx1gZd0DTOsLOLED20rvou5LM8KvVlrAxvjWVJxOE2ldG-ZPvBcdH_SsbBEzaEUSR6A';
}
