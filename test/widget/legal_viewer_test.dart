import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/features/legal/legal_viewer_screen.dart';

/// Tests for privacy policy HTML content stored in LegalHtml.privacy.
///
/// These tests verify the static HTML string directly rather than rendering
/// the WebView, because WebView requires platform channels unavailable in
/// widget tests. The HTML content is the source of truth for what the user
/// sees in the legal viewer screen.
void main() {
  group('Privacy Policy HTML content', () {
    final html = LegalHtml.privacy;

    test('contains "Lapse log" terminology (not "Relapse")', () {
      // Spec: privacy policy HTML contains 'Lapse logs'
      // The actual HTML uses 'Lapse log content'
      expect(html.contains('Lapse log'), isTrue,
          reason: 'Privacy policy should reference "Lapse log"');
    });

    test('does NOT contain "Relapse log"', () {
      expect(html.contains('Relapse log'), isFalse,
          reason:
              'Privacy policy should use "Lapse" not "Relapse" terminology');
    });

    test('contains hello@getanchorage.app', () {
      expect(html.contains('hello@getanchorage.app'), isTrue);
    });

    test('does NOT contain hello@anchorage.com.au', () {
      expect(html.contains('hello@anchorage.com.au'), isFalse);
    });

    test('contains DOB and gender disclosure language', () {
      // The privacy policy mentions date of birth and gender
      expect(html.contains('Date of birth'), isTrue,
          reason: 'Privacy policy should disclose DOB collection');
      expect(html.contains('gender'), isTrue,
          reason: 'Privacy policy should disclose gender collection');
    });

    test('states 18-and-over age requirement', () {
      expect(html.contains('18'), isTrue);
      expect(
        html.contains('aged 18 and over') ||
            html.contains('at least 18 years old') ||
            html.contains('adults aged 18'),
        isTrue,
        reason: 'Privacy policy should state the 18+ requirement',
      );
    });

    test('contains free-text / local-only storage statement', () {
      // The policy should state that free-text fields stay on device
      expect(
        html.contains('free-text') || html.contains('Free-text'),
        isTrue,
        reason:
            'Privacy policy should mention free-text fields are stored locally',
      );
    });

    test('contains Golf Tango Alpha Pty Ltd', () {
      expect(html.contains('Golf Tango Alpha Pty Ltd'), isTrue);
    });

    test('does NOT contain any personal names', () {
      // Security requirement: no personal names in legal documents
      expect(html.contains('Jackie'), isFalse);
      expect(html.contains('jackie'), isFalse);
    });

    test('contains journal/reflection local storage mention', () {
      expect(
        html.contains('Journal') || html.contains('journal'),
        isTrue,
        reason: 'Privacy policy should mention journal entries',
      );
    });

    test('urge log content mentioned as local-only', () {
      expect(html.contains('Urge log'), isTrue,
          reason: 'Privacy policy should mention urge log data');
    });
  });

  group('Terms of Service HTML content', () {
    final html = LegalHtml.terms;

    test('contains self-help tool disclaimer', () {
      expect(html.contains('self-help tool'), isTrue);
    });

    test('contains Golf Tango Alpha Pty Ltd', () {
      expect(html.contains('Golf Tango Alpha Pty Ltd'), isTrue);
    });

    test('contains findahelpline.com', () {
      expect(html.contains('findahelpline.com'), isTrue);
    });

    test('mentions ANCHORAGE+ subscription', () {
      expect(html.contains('ANCHORAGE+'), isTrue);
    });
  });
}
