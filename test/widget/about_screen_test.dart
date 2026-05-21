import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/features/about/about_screen.dart';

void main() {
  Widget buildTestWidget() {
    return MaterialApp(
      home: const AboutScreen(),
    );
  }

  group('AboutScreen', () {
    testWidgets('contains the AHPRA self-help disclaimer', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('ANCHORAGE is a self-help tool'), findsWidgets);
    });

    testWidgets('does NOT contain 85-93% or 85% or 93%', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('85-93%'), findsNothing);
      expect(find.textContaining('85%'), findsNothing);
      expect(find.textContaining('93%'), findsNothing);
    });

    testWidgets('does NOT contain "fastest known"', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('fastest known'), findsNothing);
    });

    testWidgets('does NOT contain "shame audit"', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('shame audit'), findsNothing);
    });

    testWidgets('contains Acceptance and Commitment Therapy or ACT',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Acceptance and Commitment Therapy'),
        findsWidgets,
      );
    });

    testWidgets('does NOT contain Storm anywhere visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check that no visible Text widget contains 'Storm'
      final stormFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.contains('Storm'),
      );
      expect(stormFinder, findsNothing);
    });

    testWidgets('contains findahelpline.com link', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('findahelpline.com'), findsWidgets);
    });
  });
}
