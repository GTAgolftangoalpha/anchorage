import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/features/intercept/intercept_screen.dart';
import 'package:anchorage/services/intercept_event_service.dart';
import 'package:anchorage/services/premium_service.dart';

void main() {
  group('InterceptScreen', () {
    Widget buildTestWidget() {
      return MaterialApp(
        home: const InterceptScreen(),
        routes: {
          '/reflect': (_) => const Scaffold(body: Text('Reflect')),
          '/paywall': (_) => const Scaffold(body: Text('Paywall')),
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
      // Mock SharedPreferences
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') return <String, dynamic>{};
          return null;
        },
      );

      PremiumService.instance.isPremium.value = false;
      InterceptEventService.instance.events.value = [];
    });

    tearDown(() {
      for (final channel in [
        'plugins.it_nomads.com/flutter_secure_storage',
        'plugins.flutter.io/firebase_analytics',
        'plugins.flutter.io/shared_preferences',
      ]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MethodChannel(channel), null);
      }
    });

    testWidgets('shows HOLD ON heading', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('HOLD ON'), findsOneWidget);
    });

    testWidgets('shows REFLECT ON THIS MOMENT button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('REFLECT ON THIS MOMENT'), findsOneWidget);
    });

    testWidgets('shows GO BACK TO SAFETY button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('GO BACK TO SAFETY'), findsOneWidget);
    });

    testWidgets('shows ACT prompt with title and body', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // The prompt title should be "You paused to check in. That matters."
      expect(
        find.text('You paused to check in. That matters.'),
        findsOneWidget,
      );
    });

    testWidgets('premium user does not see upgrade nudge', (tester) async {
      PremiumService.instance.isPremium.value = true;
      InterceptEventService.instance.events.value = [
        InterceptEvent(
          id: '1',
          timestamp: DateTime.now(),
          outcome: 'stayed',
          source: 'vpn_block',
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Want stronger protection next time?'),
        findsNothing,
      );
    });

    testWidgets('first-time intercept does not show upgrade nudge',
        (tester) async {
      PremiumService.instance.isPremium.value = false;
      InterceptEventService.instance.events.value = []; // No prior intercepts

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Want stronger protection next time?'),
        findsNothing,
      );
    });

    testWidgets('shows White Flag option', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('White Flag'), findsOneWidget);
    });

    testWidgets('shows blocked content message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('blocked'),
        findsWidgets,
      );
    });
  });
}
