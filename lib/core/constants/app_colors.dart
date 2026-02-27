import 'package:flutter/material.dart';
import '../../theme.dart';

/// Backwards-compatible alias — delegates to Anchorage palette.
class AppColors {
  AppColors._();

  // Primary palette
  static const Color navy = Anchorage.textPrimary;
  static const Color white = Anchorage.bgPrimary;

  // Navy shades
  static const Color navyLight = Anchorage.textSecond;
  static const Color navyDark = Anchorage.textPrimary;
  static const Color navyMid = Anchorage.textSecond;

  // Accents
  static const Color gold = Anchorage.accent;
  static const Color seafoam = Anchorage.accentLight;
  static const Color rope = Anchorage.borderMid;

  // Neutrals
  static const Color lightGray = Anchorage.bgCard;
  static const Color midGray = Anchorage.borderLight;
  static const Color slate = Anchorage.textHint;

  // Semantic
  static const Color success = Anchorage.accent;
  static const Color warning = Color(0xFFD4A03A);
  static const Color danger = Anchorage.danger;

  // Utility
  static const Color transparent = Color(0x00000000);

  // Text
  static const Color textPrimary = Anchorage.textPrimary;
  static const Color textSecondary = Anchorage.textSecond;
  static const Color textMuted = Anchorage.textHint;
}
