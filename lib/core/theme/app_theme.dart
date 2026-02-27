import '../../theme.dart';
export '../../theme.dart';

/// Backwards-compatible alias — delegates to MokusoTheme.
class AppTheme {
  AppTheme._();
  static get light => MokusoTheme.light;
}
