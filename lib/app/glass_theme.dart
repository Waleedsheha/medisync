import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glassmorphism Theme Constants & Utilities
/// Deep space aesthetic with frosted glass effects
class GlassTheme {
  // === Deep Space Palette ===
  static const Color deepBackground = Color(0xFF050508);
  static const Color surfaceBackground = Color(0xFF0A0A0F);
  static const Color cardBackground = Color(0xFF12121A);
  static const Color elevatedBackground = Color(0xFF1A1A24);

  // === Neon Accents ===
  static const Color neonCyan = Color(0xFF00D4FF);
  static const Color neonCyanLight = Color(0xFF4AE3FF);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color neonPink = Color(0xFFEC4899);

  // === Semantic ===
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // === Text ===
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textGrey = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // === Glass Effects ===
  static const double blurAmount = 20.0;
  static const Color glassBorder = Color(0xFF2A2A3A);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // === Border Radius ===
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;

  // === Text Theme ===
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textWhite,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textWhite,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textWhite,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textWhite,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textWhite,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textWhite,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: textGrey, height: 1.6),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textGrey, height: 1.5),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textWhite,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textGrey,
      ),
    );
  }

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [neonPurple, neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get glassGradient => LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.08),
      Colors.white.withValues(alpha: 0.02),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get subtleGradient => LinearGradient(
    colors: [
      neonCyan.withValues(alpha: 0.05),
      neonBlue.withValues(alpha: 0.02),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === Box Decorations ===
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: glassBorder, width: 1),
  );

  static BoxDecoration get glassDecorationSubtle => BoxDecoration(
    gradient: glassGradient,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: glassBorder.withValues(alpha: 0.5), width: 1),
  );

  static BoxDecoration glassDecorationCustom({
    double radius = 20,
    Color? color,
    double borderWidth = 1,
  }) => BoxDecoration(
    color: color ?? cardBackground,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: glassBorder, width: borderWidth),
  );

  // === Shadows ===
  static List<BoxShadow> get softGlow => [
    BoxShadow(
      color: neonCyan.withValues(alpha: 0.1),
      blurRadius: 20,
      spreadRadius: -5,
    ),
  ];

  static List<BoxShadow> get cyanGlow => [
    BoxShadow(
      color: neonCyan.withValues(alpha: 0.25),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get purpleGlow => [
    BoxShadow(
      color: neonPurple.withValues(alpha: 0.25),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];

  // === Utility Methods ===
  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'major':
      case 'critical':
      case 'high':
        return error;
      case 'moderate':
      case 'medium':
        return warning;
      case 'minor':
      case 'low':
        return success;
      default:
        return textMuted;
    }
  }
}
