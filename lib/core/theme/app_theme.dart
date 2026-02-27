import 'package:flutter/material.dart';
import '../../theme.dart';
export '../../theme.dart';

/// Backwards-compatible alias — delegates to AnchorageTheme.
class AppTheme {
  AppTheme._();
  static ThemeData get light => AnchorageTheme.light;
}
