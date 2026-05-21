import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/features/settings/settings_screen.dart';
import 'package:anchorage/services/premium_service.dart';

void main() {
  group('SettingsScreen', () {
    Widget buildTestWidget() {
      return MaterialApp(
        home: const SettingsScreen(),
      );
    }

    setUp(() {
      // Mock FlutterSecureStorage to prevent MissingPluginException
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'read') return null;
          if (methodCall.method == 'write') return null;
          if (methodCall.method == 'delete') return null;
          if (methodCall.method == 'deleteAll') return null;
          return null;
        },
      );

      // Ensure safe defaults
      PremiumService.instance.isPremium.value = false;
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    testWidgets('Send Feedback tile exists with correct icon',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to ensure feedback tile is visible
      await tester.scrollUntilVisible(
        find.text('Send Feedback'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Send Feedback'), findsOneWidget);
      expect(find.byIcon(Icons.feedback_outlined), findsOneWidget);
    });

    testWidgets('Send Feedback subtitle reads "Help us improve ANCHORAGE"',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Help us improve ANCHORAGE'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Help us improve ANCHORAGE'), findsOneWidget);
    });

    testWidgets('does NOT contain Storm anywhere visible', (tester) async {
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

    testWidgets('contains About ANCHORAGE tile', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('About ANCHORAGE'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('About ANCHORAGE'), findsOneWidget);
    });

    testWidgets('contains Delete all my data tile', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Delete all my data'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Delete all my data'), findsOneWidget);
    });

    testWidgets('contains version string', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('ANCHORAGE v1.0.0'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('ANCHORAGE v1.0.0'), findsOneWidget);
    });

    testWidgets('shows Upgrade to ANCHORAGE+ for free users', (tester) async {
      PremiumService.instance.isPremium.value = false;
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Upgrade to ANCHORAGE+'), findsOneWidget);
    });

    testWidgets('shows ANCHORAGE+ Active for premium users', (tester) async {
      PremiumService.instance.isPremium.value = true;
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ANCHORAGE+ Active'), findsOneWidget);
    });

    testWidgets('contains Get Help tile', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Get Help'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Get Help'), findsOneWidget);
    });

    testWidgets('contains Help & Legal tile', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Help & Legal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Help & Legal'), findsOneWidget);
    });
  });
}
