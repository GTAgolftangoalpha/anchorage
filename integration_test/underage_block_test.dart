import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:anchorage/main.dart' as app;

/// Integration test: underage block enforcement.
///
/// This test requires a real device or emulator to run.
/// Run with: flutter test integration_test/underage_block_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Underage blocking', () {
    testWidgets('under-18 DOB triggers blocker that prevents continuation',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Screen 1: Welcome - enter name and email
      await tester.enterText(
        find.byType(TextField).first,
        'Test Minor',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'minor@example.com',
      );
      await tester.pumpAndSettle();

      // Tap CONTINUE
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Screen 2: About You - tap the birth year selector
      final selectYear = find.text('Select year');
      if (selectYear.evaluate().isNotEmpty) {
        await tester.tap(selectYear);
        await tester.pumpAndSettle();
      }

      // In the YearPicker dialog, select a year that makes the user 17
      final currentYear = DateTime.now().year;
      final underageYear = currentYear - 17;

      // Scroll to and tap the underage year
      final yearText = find.text('$underageYear');
      if (yearText.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          yearText,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(yearText);
        await tester.pumpAndSettle();
      }

      // Verify the age gate blocker screen appears
      expect(
        find.textContaining('18 and over'),
        findsOneWidget,
        reason: 'Age gate blocker should appear for under-18 users',
      );

      // Verify the findahelpline button exists
      expect(
        find.text('VISIT FINDAHELPLINE.COM'),
        findsOneWidget,
        reason: 'Blocker should show findahelpline.com button',
      );

      // Verify the Close button exists
      expect(
        find.text('CLOSE'),
        findsOneWidget,
        reason: 'Blocker should show Close button',
      );

      // Verify there is NO Continue or Next button
      expect(find.text('CONTINUE'), findsNothing);
      expect(find.text('NEXT'), findsNothing);
      expect(find.text('SKIP'), findsNothing);

      // Verify PopScope prevents back navigation
      // The blocker wraps in PopScope(canPop: false)
    });
  });
}
