import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/leaderboard.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('parseLeaderboard', () {
    test('parses and sorts by score descending', () {
      final entries = parseLeaderboard(
        '{"entries":[{"name":"A","score":10},{"name":"B","score":50},'
        '{"name":"C","score":30}]}',
      );
      expect(entries.map((e) => e.name), ['B', 'C', 'A']);
      expect(entries.first.score, 50);
    });

    test('drops malformed rows', () {
      final entries = parseLeaderboard(
        '{"entries":[{"name":"A","score":10},{"name":"","score":5},'
        '{"nope":1},{"name":"B"},{"name":"C","score":"x"},'
        '{"name":"D","score":7}]}',
      );
      expect(entries.map((e) => e.name), ['A', 'D']);
    });

    test('missing or non-list entries yields empty', () {
      expect(parseLeaderboard('{}'), isEmpty);
      expect(parseLeaderboard('{"entries":{}}'), isEmpty);
      expect(parseLeaderboard('{"entries":[]}'), isEmpty);
    });
  });

  group('buildScoreIssueUri', () {
    test('null for empty name or non-positive score', () {
      expect(buildScoreIssueUri('', 100), isNull);
      expect(buildScoreIssueUri('Max', 0), isNull);
      expect(buildScoreIssueUri('Max', -5), isNull);
    });

    test('carries the score label and a parseable marker', () {
      final uri = buildScoreIssueUri('Max', 12345)!;
      expect(uri.host, 'github.com');
      expect(uri.path, '/f6vp76ctbb-stack/mobile-game/issues/new');
      expect(uri.queryParameters['labels'], 'score');
      expect(
        uri.queryParameters['body'],
        contains('<!-- qubble-score v1 name="Max" score="12345" -->'),
      );
    });

    test('the marker matches the Action regex', () {
      final uri = buildScoreIssueUri('Ann_1', 42)!;
      final body = uri.queryParameters['body']!;
      final re = RegExp(r'qubble-score\s+v1\s+name="([^"]{2,14})"\s+score="(\d{1,9})"');
      final m = re.firstMatch(body);
      expect(m, isNotNull);
      expect(m!.group(1), 'Ann_1');
      expect(m.group(2), '42');
    });
  });

  group('LeaderboardService.fetchTop', () {
    test('parses a successful response and applies the limit', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'raw.githubusercontent.com');
        return http.Response(
          '{"entries":[{"name":"A","score":3},{"name":"B","score":9},'
          '{"name":"C","score":6}]}',
          200,
        );
      });
      final service = LeaderboardService(client: client);
      final top2 = await service.fetchTop(limit: 2);
      expect(top2.map((e) => e.name), ['B', 'C']);
    });

    test('throws on a non-200 response', () async {
      final client = MockClient((req) async => http.Response('nope', 404));
      final service = LeaderboardService(client: client);
      expect(service.fetchTop(), throwsA(isA<Exception>()));
    });
  });
}
