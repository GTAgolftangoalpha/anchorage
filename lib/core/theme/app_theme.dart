import 'package:flutter/material.dart';
import '../../theme.dart';
export '../../theme.dart';

/// Backwards-compatible alias. Delegates to AnchorageTheme.
class AppTheme {
  AppTheme._();
  static ThemeData get light => AnchorageTheme.light;
}
