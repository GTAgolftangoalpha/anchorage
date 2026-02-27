import 'package:flutter/material.dart';
import '../../theme.dart';

/// Backwards-compatible alias — delegates to Mokuso palette.
class AppColors {
  AppColors._();

  // Primary palette (Mokuso)
  static const Color navy = Mokuso.textPrimary;
  static const Color white = Mokuso.bgPrimary;

  // Navy shades → charcoal shades
  static const Color navyLight = Mokuso.textSecond;
  static const Color navyDark = Mokuso.textPrimary;
  static const Color navyMid = Mokuso.textSecond;

  // Accents
  static const Color gold = Mokuso.accent;
  static const Color seafoam = Mokuso.accentLight;
  static const Color rope = Mokuso.borderMid;

  // Neutrals
  static const Color lightGray = Mokuso.bgCard;
  static const Color midGray = Mokuso.borderLight;
  static const Color slate = Mokuso.textHint;

  // Semantic
  static const Color success = Mokuso.accent;
  static const Color warning = Color(0xFFD4A03A);
  static const Color danger = Mokuso.danger;

  // Utility
  static const Color transparent = Color(0x00000000);

  // Text
  static const Color textPrimary = Mokuso.textPrimary;
  static const Color textSecondary = Mokuso.textSecond;
  static const Color textMuted = Mokuso.textHint;
}
