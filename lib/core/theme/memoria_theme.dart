import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'memoria_tokens.dart';

abstract class MemoriaTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: MemoriaTokens.surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: MemoriaTokens.primary,
        onPrimary: MemoriaTokens.onPrimary,
        primaryContainer: MemoriaTokens.primaryContainer,
        onPrimaryContainer: MemoriaTokens.primaryDark,
        secondary: MemoriaTokens.secondary,
        onSecondary: MemoriaTokens.onSecondary,
        secondaryContainer: MemoriaTokens.secondaryContainer,
        onSecondaryContainer: MemoriaTokens.secondary,
        tertiary: MemoriaTokens.tertiary,
        onTertiary: MemoriaTokens.onTertiary,
        tertiaryContainer: MemoriaTokens.tertiaryContainer,
        onTertiaryContainer: MemoriaTokens.onTertiary,
        error: MemoriaTokens.error,
        onError: Colors.white,
        surface: MemoriaTokens.surface,
        onSurface: MemoriaTokens.onSurface,
        onSurfaceVariant: MemoriaTokens.onSurfaceVariant,
        outline: MemoriaTokens.outline,
        outlineVariant: MemoriaTokens.outlineVariant,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: MemoriaTokens.displayLg(),
        headlineLarge: MemoriaTokens.headlineLg(),
        headlineMedium: MemoriaTokens.headlineMd(),
        headlineSmall: MemoriaTokens.headlineSm(),
        bodyLarge: MemoriaTokens.bodyLg(),
        bodyMedium: MemoriaTokens.bodyMd(),
        bodySmall: MemoriaTokens.bodySm(),
        labelLarge: MemoriaTokens.labelLg(),
        labelMedium: MemoriaTokens.labelMd(),
        labelSmall: MemoriaTokens.labelSm(),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: MemoriaTokens.onSurface),
        titleTextStyle: TextStyle(
          color: MemoriaTokens.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
      cardTheme: CardThemeData(
        color: MemoriaTokens.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MemoriaTokens.radiusMd),
          side: const BorderSide(color: MemoriaTokens.polaroidBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MemoriaTokens.primary,
          foregroundColor: MemoriaTokens.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MemoriaTokens.onSurface,
          side: const BorderSide(color: MemoriaTokens.outlineVariant, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MemoriaTokens.radiusPill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
