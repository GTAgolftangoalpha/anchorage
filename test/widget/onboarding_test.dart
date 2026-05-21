import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/features/onboarding/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    Widget buildTestWidget() {
      return MaterialApp(
        home: const OnboardingScreen(),
        routes: {
          '/home': (_) => const Scaffold(body: Text('Home')),
        },
      );
    }

    setUp(() {
      // Mock all platform channels that OnboardingScreen's initState touches.

      // GuardService: com.anchorage.app/guard
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.anchorage.app/guard'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'hasUsagePermission') return false;
          if (methodCall.method == 'hasOverlayPermission') return false;
          if (methodCall.method == 'isBatteryOptimizationExempt') return false;
          if (methodCall.method == 'loadGuardedPackages') return <String>[];
          return null;
        },
      );

      // VpnService: com.anchorage.app/vpn
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.anchorage.app/vpn'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isVpnActive') return false;
          if (methodCall.method == 'prepareVpn') return false;
          return null;
        },
      );

      // TamperService: com.anchorage.app/tamper
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.anchorage.app/tamper'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isDeviceAdminActive') return false;
          return null;
        },
      );

      // FlutterSecureStorage
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async => null,
      );

      // Firebase Analytics
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_analytics'),
        (MethodCall methodCall) async => null,
      );

      // url_launcher
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher_android'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'canLaunch') return true;
          if (methodCall.method == 'launch') return true;
          return null;
        },
      );
    });

    tearDown(() {
      for (final channel in [
        'com.anchorage.app/guard',
        'com.anchorage.app/vpn',
        'com.anchorage.app/tamper',
        'plugins.it_nomads.com/flutter_secure_storage',
        'plugins.flutter.io/firebase_analytics',
        'plugins.flutter.io/url_launcher_android',
      ]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MethodChannel(channel), null);
      }
    });

    testWidgets('shows ANCHORAGE title on welcome screen', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ANCHORAGE'), findsOneWidget);
    });

    testWidgets('shows name input field on welcome screen', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('What should we call you?'), findsOneWidget);
    });

    testWidgets('CONTINUE button is initially disabled', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final button = find.widgetWithText(FilledButton, 'CONTINUE');
      expect(button, findsOneWidget);
      final filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNull,
          reason: 'CONTINUE should be disabled until name and email entered');
    });

    testWidgets('entering valid name and email enables CONTINUE',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter a valid name
      await tester.enterText(find.byType(TextField).first, 'TestUser');
      await tester.pump();

      // Enter a valid email
      await tester.enterText(find.byType(TextField).last, 'test@example.com');
      await tester.pump();

      final button = find.widgetWithText(FilledButton, 'CONTINUE');
      final filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNotNull,
          reason: 'CONTINUE should be enabled with valid name and email');
    });

    testWidgets('navigating to About You page shows gender chips',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter valid name and email to enable CONTINUE
      await tester.enterText(find.byType(TextField).first, 'TestUser');
      await tester.enterText(find.byType(TextField).last, 'test@example.com');
      await tester.pump();

      // Tap CONTINUE to go to About You page
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Verify "A bit about you" heading
      expect(find.text('A bit about you'), findsOneWidget);

      // Verify 4 gender chips
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Non-binary'), findsOneWidget);
      // "Prefer not to say" appears twice: as gender chip and DOB skip
      expect(find.text('Prefer not to say'), findsWidgets);
    });

    testWidgets('About You page has Skip button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Navigate to About You page
      await tester.enterText(find.byType(TextField).first, 'TestUser');
      await tester.enterText(find.byType(TextField).last, 'test@example.com');
      await tester.pump();
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Verify Skip button exists
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('About You page has birth year selector', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Navigate to About You page
      await tester.enterText(find.byType(TextField).first, 'TestUser');
      await tester.enterText(find.byType(TextField).last, 'test@example.com');
      await tester.pump();
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Verify birth year selector ("Select year" button text)
      expect(find.text('Select year'), findsOneWidget);
      expect(find.text('When were you born?'), findsOneWidget);
    });

    testWidgets('does NOT contain Storm anywhere', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final stormFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.contains('Storm'),
      );
      expect(stormFinder, findsNothing);
    });

    testWidgets('self-help disclaimer shown on welcome page', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('self-help tool'),
        findsOneWidget,
      );
    });
  });
}
