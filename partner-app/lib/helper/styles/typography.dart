import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system with optimized letter spacing and line height
/// for aesthetically pleasing text rendering across the app
class AppTypography {
  /// Calculate optimal letter spacing based on font size
  /// Larger fonts need tighter spacing, smaller fonts need more breathing room
  static double getLetterSpacing(double fontSize) {
    if (fontSize >= 24) {
      return -0.5; // Large headings: tight spacing
    } else if (fontSize >= 20) {
      return -0.4; // Medium headings
    } else if (fontSize >= 16) {
      return -0.3; // Small headings
    } else if (fontSize >= 14) {
      return -0.2; // Body text
    } else if (fontSize >= 12) {
      return -0.15; // Small text
    } else {
      return -0.1; // Tiny text
    }
  }

  /// Calculate optimal line height based on font size
  /// Proper line height improves readability
  static double getLineHeight(double fontSize) {
    if (fontSize >= 24) {
      return 1.2; // Large headings: tight line height
    } else if (fontSize >= 20) {
      return 1.25; // Medium headings
    } else if (fontSize >= 16) {
      return 1.3; // Small headings
    } else if (fontSize >= 14) {
      return 1.4; // Body text: more breathing room
    } else if (fontSize >= 12) {
      return 1.45; // Small text
    } else {
      return 1.5; // Tiny text: maximum readability
    }
  }

  /// Create an Inter text style with optimal spacing
  static TextStyle inter({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? getLetterSpacing(fontSize),
      height: height ?? getLineHeight(fontSize),
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  /// Create a Roboto text style with optimal spacing
  static TextStyle roboto({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return GoogleFonts.roboto(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? getLetterSpacing(fontSize),
      height: height ?? getLineHeight(fontSize),
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  // Predefined text styles for common use cases

  /// Large display text (32px+)
  static TextStyle displayLarge({required Color color}) {
    return inter(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Medium display text (28px)
  static TextStyle displayMedium({required Color color}) {
    return inter(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Small display text (24px)
  static TextStyle displaySmall({required Color color}) {
    return inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Large heading (20px)
  static TextStyle headingLarge({required Color color}) {
    return inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Medium heading (18px)
  static TextStyle headingMedium({required Color color}) {
    return inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Small heading (16px)
  static TextStyle headingSmall({required Color color}) {
    return inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Large body text (16px)
  static TextStyle bodyLarge(
      {required Color color, FontWeight? fontWeight}) {
    return inter(
      fontSize: 16,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Medium body text (14px)
  static TextStyle bodyMedium(
      {required Color color, FontWeight? fontWeight}) {
    return inter(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Small body text (12px)
  static TextStyle bodySmall(
      {required Color color, FontWeight? fontWeight}) {
    return inter(
      fontSize: 12,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Caption text (11px)
  static TextStyle caption(
      {required Color color, FontWeight? fontWeight}) {
    return inter(
      fontSize: 11,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Tiny text (10px)
  static TextStyle tiny({required Color color, FontWeight? fontWeight}) {
    return inter(
      fontSize: 10,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Button text (14px)
  static TextStyle button({required Color color}) {
    return inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }

  /// Label text (13px)
  static TextStyle label({required Color color, FontWeight? fontWeight}) {
    return inter(
      fontSize: 13,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: -0.55,
      height: 1.15,
    );
  }
}
