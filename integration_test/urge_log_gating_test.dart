import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:anchorage/services/premium_service.dart';
import 'package:anchorage/services/urge_log_service.dart';
import 'package:anchorage/features/urge_log/urge_log_screen.dart';
import 'package:flutter/material.dart';

/// Integration test: urge log free tier gating.
///
/// This test requires a real device or emulator to run.
/// Run with: flutter test integration_test/urge_log_gating_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Urge log gating', () {
    testWidgets('free user sees counter decrement and upgrade card at limit',
        (tester) async {
      // Set up free user with empty urge log
      PremiumService.instance.isPremium.value = false;
      UrgeLogService.instance.entries.value = [];

      await tester.pumpWidget(MaterialApp(
        home: const UrgeLogScreen(),
        routes: {
          '/paywall': (_) => const Scaffold(body: Text('Paywall Screen')),
          '/sos': (_) => const Scaffold(body: Text('SOS')),
        },
      ));
      await tester.pumpAndSettle();

      // Verify starting state: 3 of 3
      expect(find.text('3 of 3 logs remaining this month'), findsOneWidget);

      // Log entry 1
      final now = DateTime.now();
      UrgeLogService.instance.entries.value = [
        UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
      ];
      await tester.pumpAndSettle();

      expect(find.text('2 of 3 logs remaining this month'), findsOneWidget);

      // Log entry 2
      UrgeLogService.instance.entries.value = [
        UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
        UrgeEntry(id: '2', timestamp: now, trigger: 'Stress'),
      ];
      await tester.pumpAndSettle();

      expect(find.text('1 of 3 logs remaining this month'), findsOneWidget);

      // Log entry 3
      UrgeLogService.instance.entries.value = [
        UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
        UrgeEntry(id: '2', timestamp: now, trigger: 'Stress'),
        UrgeEntry(id: '3', timestamp: now, trigger: 'Loneliness'),
      ];
      await tester.pumpAndSettle();

      // Verify 0 remaining
      expect(find.text('0 of 3 logs remaining this month'), findsOneWidget);

      // Verify upgrade card appears
      expect(find.text('You are building self-awareness.'), findsOneWidget);

      // Verify UPGRADE button is present
      expect(find.text('UPGRADE'), findsOneWidget);

      // Tap UPGRADE and verify navigation toward paywall
      await tester.tap(find.text('UPGRADE'));
      await tester.pumpAndSettle();

      expect(find.text('Paywall Screen'), findsOneWidget);
    });
  });
}
