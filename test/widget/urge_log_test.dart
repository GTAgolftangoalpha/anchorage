import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/features/urge_log/urge_log_screen.dart';
import 'package:anchorage/services/premium_service.dart';
import 'package:anchorage/services/urge_log_service.dart';

void main() {
  group('UrgeLogScreen', () {
    Widget buildTestWidget() {
      return MaterialApp(
        home: const UrgeLogScreen(),
        routes: {
          '/paywall': (_) => const Scaffold(body: Text('Paywall')),
          '/sos': (_) => const Scaffold(body: Text('SOS')),
        },
      );
    }

    setUp(() {
      // Mock secure storage
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async => null,
      );
      // Mock firebase analytics
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_analytics'),
        (MethodCall methodCall) async => null,
      );
      // Reset state
      UrgeLogService.instance.entries.value = [];
      PremiumService.instance.isPremium.value = false;
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_analytics'),
        null,
      );
    });

    testWidgets('free user with 0 entries sees "3 of 3 logs remaining"',
        (tester) async {
      UrgeLogService.instance.entries.value = [];
      PremiumService.instance.isPremium.value = false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('3 of 3 logs remaining this month'), findsOneWidget);
    });

    testWidgets('free user with 2 entries sees "1 of 3 logs remaining"',
        (tester) async {
      final now = DateTime.now();
      UrgeLogService.instance.entries.value = [
        UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
        UrgeEntry(id: '2', timestamp: now, trigger: 'Stress'),
      ];
      PremiumService.instance.isPremium.value = false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('1 of 3 logs remaining this month'), findsOneWidget);
    });

    testWidgets(
        'free user with 3 entries sees upgrade card with self-awareness text',
        (tester) async {
      final now = DateTime.now();
      UrgeLogService.instance.entries.value = [
        UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
        UrgeEntry(id: '2', timestamp: now, trigger: 'Stress'),
        UrgeEntry(id: '3', timestamp: now, trigger: 'Anxiety'),
      ];
      PremiumService.instance.isPremium.value = false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('You are building self-awareness.'),
        findsOneWidget,
      );
    });

    testWidgets('free user with 3 entries sees LOG ENTRY button disabled',
        (tester) async {
      final now = DateTime.now();
      UrgeLogService.instance.entries.value = [
        UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
        UrgeEntry(id: '2', timestamp: now, trigger: 'Stress'),
        UrgeEntry(id: '3', timestamp: now, trigger: 'Anxiety'),
      ];
      PremiumService.instance.isPremium.value = false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to the LOG ENTRY button
      await tester.scrollUntilVisible(
        find.text('LOG ENTRY'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // Find the LOG ENTRY button and verify it is disabled
      final buttonFinder = find.widgetWithText(FilledButton, 'LOG ENTRY');
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNull,
          reason: 'LOG ENTRY should be disabled when limit reached');
    });

    testWidgets('premium user does not see counter or upgrade card',
        (tester) async {
      PremiumService.instance.isPremium.value = true;
      UrgeLogService.instance.entries.value = [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('of 3 logs remaining'), findsNothing);
      expect(find.text('You are building self-awareness.'), findsNothing);
    });

    testWidgets('existing entries display in list', (tester) async {
      final now = DateTime.now();
      UrgeLogService.instance.entries.value = [
        UrgeEntry(
            id: '1',
            timestamp: now,
            trigger: 'Late night',
            notes: 'Unique test note'),
      ];
      PremiumService.instance.isPremium.value = false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to reveal entry cards
      await tester.scrollUntilVisible(
        find.text('Unique test note'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // The trigger name and notes appear in the entry card
      expect(find.text('Late night'), findsWidgets);
      expect(find.text('Unique test note'), findsOneWidget);
    });

    testWidgets('"Need to talk to someone?" link is present', (tester) async {
      UrgeLogService.instance.entries.value = [];
      PremiumService.instance.isPremium.value = false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Need to talk to someone?'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Need to talk to someone?'), findsOneWidget);
    });

    testWidgets('shows URGE LOG in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('URGE LOG'), findsOneWidget);
    });

    testWidgets('shows "0 of 3 logs remaining" with 3 entries',
        (tester) async {
      final now = DateTime.now();
      UrgeLogService.instance.entries.value = [
        UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
        UrgeEntry(id: '2', timestamp: now, trigger: 'Stress'),
        UrgeEntry(id: '3', timestamp: now, trigger: 'Anxiety'),
      ];
      PremiumService.instance.isPremium.value = false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('0 of 3 logs remaining this month'), findsOneWidget);
    });

    testWidgets('upgrade card has UPGRADE button', (tester) async {
      final now = DateTime.now();
      UrgeLogService.instance.entries.value = [
        UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
        UrgeEntry(id: '2', timestamp: now, trigger: 'Stress'),
        UrgeEntry(id: '3', timestamp: now, trigger: 'Anxiety'),
      ];
      PremiumService.instance.isPremium.value = false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('UPGRADE'), findsOneWidget);
    });
  });
}
