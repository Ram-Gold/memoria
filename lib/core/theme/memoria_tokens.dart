import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tactile Editorial Analog design system tokens for Memoria
abstract class MemoriaTokens {
  // --- Paper & Substrate Surfaces ---
  static const Color surface = Color(0xFFFDF8F6);
  static const Color surfaceDim = Color(0xFFDDD9D7);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F3F0);
  static const Color surfaceContainer = Color(0xFFF1ECE8);
  static const Color surfaceContainerHigh = Color(0xFFE8E2DE);
  static const Color surfaceContainerHighest = Color(0xFFDED7D2);

  // --- Film & Hardware Surfaces ---
  static const Color polaroidCard = Color(0xFFF8F6F0);
  static const Color polaroidBorder = Color(0xFFE8E4DF);
  static const Color cameraObsidian = Color(0xFF1A1918);
  static const Color emulsionDark = Color(0xFF131518);
  static const Color viewfinderOverlay = Color(0xCC121316);

  // --- Ink & Text Contrasts ---
  static const Color onSurface = Color(0xFF1C1B1A);
  static const Color onSurfaceVariant = Color(0xFF584239);
  static const Color outline = Color(0xFF8C7167);
  static const Color outlineVariant = Color(0xFFDFC0B4);

  // --- Brand & Pedagogical Accents ---
  static const Color primary = Color(0xFFE36528); // Darkroom amber / terracotta
  static const Color primaryDark = Color(0xFFA13B00);
  static const Color primaryContainer = Color(0xFFFAEDE8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF4A5B4C); // Muted nori olive
  static const Color secondaryContainer = Color(0xFFD4E8D4);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color tertiary = Color(0xFF34435E); // Washed indigo
  static const Color tertiaryContainer = Color(0xFF667592);
  static const Color onTertiary = Color(0xFFFFFFFF);

  static const Color stampVermilion = Color(0xFFBA1A1A); // Analog rubber stamp red
  static const Color stampVermilionSoft = Color(0xFFF8E6E6);

  static const Color error = Color(0xFFBA1A1A);

  // --- Geometry Radii ---
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0;

  // --- Elevations & Shadows ---
  static const List<BoxShadow> shadowLevel1 = [
    BoxShadow(
      color: Color(0x0D1C1B1A),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A1C1B1A),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> shadowPolaroid = [
    BoxShadow(
      color: Color(0x121C1B1A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x1A1C1B1A),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0D1C1B1A),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> shadowCapsule = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 20,
      spreadRadius: 1,
      offset: Offset(0, 6),
    ),
  ];

  // --- Typography Styles ---
  static TextStyle displayLg({Color color = onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.02,
        color: color,
      );

  static TextStyle headlineLg({Color color = onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.015,
        color: color,
      );

  static TextStyle headlineMd({Color color = onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.01,
        color: color,
      );

  static TextStyle headlineSm({Color color = onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle bodyLg({Color color = onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMd({Color color = onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySm({Color color = onSurfaceVariant}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  static TextStyle labelLg({Color color = onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.02,
        color: color,
      );

  static TextStyle labelMd({Color color = onSurfaceVariant}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.04,
        color: color,
      );

  static TextStyle labelSm({Color color = onSurfaceVariant}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06,
        color: color,
      );

  // Handwritten Polaroid chin calligraphy script
  static TextStyle handwrittenChin({
    double fontSize = 28,
    Color color = onSurface,
  }) =>
      GoogleFonts.caveat(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: 0.02,
        color: color,
      );

  // Monospace for ISO / Telemetry / Coordinates
  static TextStyle telemetryMono({
    double fontSize = 10,
    Color color = onSurfaceVariant,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: 0.08,
        color: color,
      );
}
