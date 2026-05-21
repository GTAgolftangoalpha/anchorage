import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/features/reflect/reflect_screen.dart';
import 'package:anchorage/features/relapse_log/relapse_log_screen.dart';
import 'package:anchorage/services/premium_service.dart';
import 'package:anchorage/services/reflect_service.dart';
import 'package:anchorage/services/relapse_service.dart';

void main() {
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

    PremiumService.instance.isPremium.value = true;
    ReflectService.instance.entries.value = [];
    RelapseService.instance.entries.value = [];
  });

  tearDown(() {
    for (final channel in [
      'plugins.it_nomads.com/flutter_secure_storage',
      'plugins.flutter.io/firebase_analytics',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), null);
    }
  });

  group('ReflectScreen', () {
    Widget buildReflectWidget() {
      return MaterialApp(
        home: const ReflectScreen(),
        routes: {
          '/sos': (_) => const Scaffold(body: Text('SOS')),
          '/home': (_) => const Scaffold(body: Text('Home')),
          '/relapse-log': (_) => const Scaffold(body: Text('Lapse Log')),
        },
      );
    }

    testWidgets('shows grounding prompt text', (tester) async {
      await tester.pumpWidget(buildReflectWidget());
      await tester.pumpAndSettle();

      // The reflect screen shows:
      // "Before you write, take a breath. Notice where you are right now.
      //  You are not in that moment any more. This is a space to understand,
      //  not to judge."
      expect(
        find.textContaining('take a breath'),
        findsOneWidget,
      );
    });

    testWidgets('shows "Need to talk to someone?" link', (tester) async {
      await tester.pumpWidget(buildReflectWidget());
      await tester.pumpAndSettle();

      expect(find.text('Need to talk to someone?'), findsOneWidget);
    });

    testWidgets('grounding prompt has teal background color', (tester) async {
      await tester.pumpWidget(buildReflectWidget());
      await tester.pumpAndSettle();

      // Find the Container with the grounding prompt by its decoration color
      final containers = tester.widgetList<Container>(find.byType(Container));
      final tealContainer = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == const Color(0xFF1A6B72);
        }
        return false;
      });
      expect(tealContainer, isNotEmpty,
          reason: 'Should have a teal (0xFF1A6B72) background container');
    });

    testWidgets('shows mood selector options', (tester) async {
      await tester.pumpWidget(buildReflectWidget());
      await tester.pumpAndSettle();

      expect(find.text('Strong'), findsOneWidget);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Frustrated'), findsOneWidget);
      expect(find.text('Anxious'), findsOneWidget);
      expect(find.text('Down'), findsOneWidget);
      expect(find.text('Not sure'), findsOneWidget);
    });

    testWidgets('shows SAVE REFLECTION button', (tester) async {
      await tester.pumpWidget(buildReflectWidget());
      await tester.pumpAndSettle();

      expect(find.text('SAVE REFLECTION'), findsOneWidget);
    });
  });

  group('RelapseLogScreen (Lapse Log)', () {
    Widget buildLapseWidget() {
      return MaterialApp(
        home: const RelapseLogScreen(),
        routes: {
          '/sos': (_) => const Scaffold(body: Text('SOS')),
          '/paywall': (_) => const Scaffold(body: Text('Paywall')),
        },
      );
    }

    testWidgets('shows grounding prompt when premium', (tester) async {
      PremiumService.instance.isPremium.value = true;

      await tester.pumpWidget(buildLapseWidget());
      await tester.pumpAndSettle();

      // Lapse log grounding prompt:
      // "This took courage. There is no judgment here. Let us look at what
      //  happened together."
      expect(
        find.textContaining('courage'),
        findsOneWidget,
      );
    });

    testWidgets('shows "Need to talk to someone?" link when premium',
        (tester) async {
      PremiumService.instance.isPremium.value = true;

      await tester.pumpWidget(buildLapseWidget());
      await tester.pumpAndSettle();

      // The crisis link is at the bottom, may need scrolling
      await tester.scrollUntilVisible(
        find.text('Need to talk to someone?'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Need to talk to someone?'), findsOneWidget);
    });

    testWidgets('grounding prompt has teal background color when premium',
        (tester) async {
      PremiumService.instance.isPremium.value = true;

      await tester.pumpWidget(buildLapseWidget());
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final tealContainer = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == const Color(0xFF1A6B72);
        }
        return false;
      });
      expect(tealContainer, isNotEmpty,
          reason: 'Lapse log should have teal grounding prompt container');
    });

    testWidgets('shows LAPSE LOG in app bar', (tester) async {
      await tester.pumpWidget(buildLapseWidget());
      await tester.pumpAndSettle();

      expect(find.text('LAPSE LOG'), findsOneWidget);
    });

    testWidgets('shows premium gate for free users', (tester) async {
      PremiumService.instance.isPremium.value = false;

      await tester.pumpWidget(buildLapseWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('ANCHORAGE+ feature'),
        findsOneWidget,
      );
    });

    testWidgets('shows "A setback is not failure" explainer', (tester) async {
      await tester.pumpWidget(buildLapseWidget());
      await tester.pumpAndSettle();

      expect(find.text('A setback is not failure'), findsOneWidget);
    });
  });
}
