import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/feedback.dart';

void main() {
  group('buildFeedbackIssueUri', () {
    test('returns null for blank text', () {
      expect(buildFeedbackIssueUri(''), isNull);
      expect(buildFeedbackIssueUri('   \n  '), isNull);
    });

    test('targets the repo new-issue endpoint with the feedback label', () {
      final uri = buildFeedbackIssueUri('Tolle App')!;
      expect(uri.scheme, 'https');
      expect(uri.host, 'github.com');
      expect(uri.path, '/f6vp76ctbb-stack/mobile-game/issues/new');
      expect(uri.queryParameters['labels'], kFeedbackLabel);
    });

    test('title uses the first line, prefixed and clipped', () {
      final short = buildFeedbackIssueUri('Bombe ruckelt\nmehr Details')!;
      expect(short.queryParameters['title'], 'Feedback: Bombe ruckelt');

      final long = buildFeedbackIssueUri('x' * 100)!;
      final title = long.queryParameters['title']!;
      expect(title.startsWith('Feedback: '), isTrue);
      expect(title.endsWith('…'), isTrue);
      expect(title.length, lessThanOrEqualTo('Feedback: '.length + 60));
    });

    test('body carries the full text plus the context block', () {
      final uri = buildFeedbackIssueUri(
        'Zeile eins\nZeile zwei',
        context: {'Plattform': 'Web/PWA'},
      )!;
      final body = uri.queryParameters['body']!;
      expect(body, contains('Zeile eins'));
      expect(body, contains('Zeile zwei'));
      expect(body, contains('- Plattform: Web/PWA'));
    });

    test('honours a custom target', () {
      final uri = buildFeedbackIssueUri(
        'hi',
        target: const FeedbackTarget(owner: 'me', repo: 'thing'),
      )!;
      expect(uri.path, '/me/thing/issues/new');
    });
  });
}
