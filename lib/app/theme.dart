import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MediSync Dark Theme
/// Deep space aesthetic with cyan/blue accents and glassmorphism
class AppTheme {
  // === Core Palette ===
  static const _deepBlack = Color(0xFF050508); // True deep black
  static const _surfaceBlack = Color(0xFF0A0A0F); // Slightly lighter surface
  static const _cardSurface = Color(0xFF12121A); // Card backgrounds
  static const _elevatedSurface = Color(0xFF1A1A24); // Elevated elements

  // === Accent Colors ===
  static const _cyanPrimary = Color(0xFF00D4FF); // Primary cyan
  static const _cyanLight = Color(0xFF4AE3FF); // Light cyan for highlights
  static const _blueSecondary = Color(0xFF3B82F6); // Secondary blue
  static const _purpleAccent = Color(0xFF8B5CF6); // Purple for special elements

  // === Semantic Colors (exposed for use) ===
  static const success = Color(0xFF10B981); // Green
  static const warning = Color(0xFFF59E0B); // Amber
  static const error = Color(0xFFEF4444); // Red

  // === Text Colors ===
  static const _textPrimary = Color(0xFFF8FAFC); // Near-white
  static const _textSecondary = Color(0xFF94A3B8); // Muted slate
  static const _textMuted = Color(0xFF64748B); // Very muted

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _deepBlack,
      primaryColor: _cyanPrimary,
      colorScheme: const ColorScheme.dark(
        primary: _cyanPrimary,
        onPrimary: _deepBlack,
        secondary: _blueSecondary,
        onSecondary: _textPrimary,
        tertiary: _purpleAccent,
        surface: _surfaceBlack,
        surfaceContainer: _cardSurface,
        surfaceContainerHigh: _elevatedSurface,
        error: error,
        onSurface: _textPrimary,
        onSurfaceVariant: _textSecondary,
        outline: Color(0xFF2A2A3A),
        outlineVariant: Color(0xFF1F1F2E),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: _textSecondary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: _textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: _textMuted),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _deepBlack,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        iconTheme: const IconThemeData(color: _textPrimary, size: 22),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceBlack,
        selectedItemColor: _cyanPrimary,
        unselectedItemColor: _textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceBlack,
        indicatorColor: _cyanPrimary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _cyanPrimary,
            );
          }
          return GoogleFonts.inter(fontSize: 12, color: _textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _cyanPrimary, size: 24);
          }
          return const IconThemeData(color: _textMuted, size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardSurface,
        hintStyle: const TextStyle(color: _textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A2A3A), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A2A3A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _cyanPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1F1F2E), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: _textMuted,
        showDragHandle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _cyanPrimary,
          foregroundColor: _deepBlack,
          disabledBackgroundColor: _cardSurface,
          disabledForegroundColor: _textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _cyanPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          side: const BorderSide(color: _cyanPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _cyanPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _cyanPrimary,
        foregroundColor: _deepBlack,
        elevation: 0,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _cardSurface,
        selectedColor: _cyanPrimary.withValues(alpha: 0.15),
        side: const BorderSide(color: Color(0xFF2A2A3A)),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: _textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _textSecondary,
        textColor: _textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1F1F2E),
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _elevatedSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(fontSize: 13, color: _textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _elevatedSurface,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: _textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: const IconThemeData(color: _cyanLight, size: 24),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _cyanPrimary;
          return _textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _cyanPrimary.withValues(alpha: 0.3);
          }
          return _cardSurface;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _cyanPrimary,
        linearTrackColor: _cardSurface,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: _cyanPrimary,
        labelColor: _cyanPrimary,
        unselectedLabelColor: _textMuted,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
      ),
    );
  }

  static ThemeData get light => dark;
}
