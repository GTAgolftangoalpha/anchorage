import 'package:flutter/material.dart';

/// Global navigator key shared between main.dart (app startup) and
/// app_router.dart (GoRouter config) without creating a circular import.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
