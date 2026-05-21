import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:anchorage/main.dart' as app;

/// Integration test: full onboarding happy path.
///
/// This test requires a real device or emulator to run.
/// Run with: flutter test integration_test/onboarding_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding flow', () {
    testWidgets('completes happy path from launch to home screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Screen 1: Welcome - enter name and email
      await tester.enterText(
        find.byType(TextField).first,
        'Test User',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'test@example.com',
      );
      await tester.pumpAndSettle();

      // Tap CONTINUE
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Screen 2: About You - tap "Prefer not to say" for gender
      final preferNotToSayChips = find.text('Prefer not to say');
      if (preferNotToSayChips.evaluate().isNotEmpty) {
        await tester.tap(preferNotToSayChips.first);
        await tester.pumpAndSettle();
      }

      // Skip DOB by tapping "Prefer not to say" under birth year
      // Then tap Skip to advance
      final skipButton = find.text('Skip');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      // Screen 3: Values - select at least one value and continue
      final valueFinder = find.text('Trust');
      if (valueFinder.evaluate().isNotEmpty) {
        await tester.tap(valueFinder);
        await tester.pumpAndSettle();
      }

      // Tap CONTINUE on values screen
      final continueButton = find.text('CONTINUE');
      if (continueButton.evaluate().isNotEmpty) {
        await tester.tap(continueButton);
        await tester.pumpAndSettle();
      }

      // Screen 4: Permissions - skip (permissions require actual device APIs)
      final skipPerms = find.text('SKIP FOR NOW');
      if (skipPerms.evaluate().isNotEmpty) {
        await tester.tap(skipPerms);
        await tester.pumpAndSettle();
      } else {
        final continuePerms = find.text('CONTINUE');
        if (continuePerms.evaluate().isNotEmpty) {
          await tester.tap(continuePerms);
          await tester.pumpAndSettle();
        }
      }

      // Screen 5: Guarded Apps - skip
      final skipApps = find.text('SKIP FOR NOW');
      if (skipApps.evaluate().isNotEmpty) {
        await tester.tap(skipApps);
        await tester.pumpAndSettle();
      } else {
        final continueApps = find.text('CONTINUE');
        if (continueApps.evaluate().isNotEmpty) {
          await tester.tap(continueApps);
          await tester.pumpAndSettle();
        }
      }

      // Screen 6: Accountability - skip partner
      final skipPartner = find.text('SKIP');
      final finishButton = find.text('FINISH');
      final getStarted = find.text('GET STARTED');
      if (skipPartner.evaluate().isNotEmpty) {
        await tester.tap(skipPartner);
        await tester.pumpAndSettle();
      } else if (finishButton.evaluate().isNotEmpty) {
        await tester.tap(finishButton);
        await tester.pumpAndSettle();
      } else if (getStarted.evaluate().isNotEmpty) {
        await tester.tap(getStarted);
        await tester.pumpAndSettle();
      }

      // Should now be on home screen
      // Verify the home screen is visible
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Home screen should show the user's name or streak counter
      expect(
        find.textContaining('Test User').evaluate().isNotEmpty ||
            find.textContaining('day').evaluate().isNotEmpty ||
            find.byType(BottomNavigationBar).evaluate().isNotEmpty,
        isTrue,
        reason: 'Should arrive at home screen after onboarding',
      );
    });
  });
}
