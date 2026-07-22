import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/leaderboard.dart';
import 'package:gridpop/services/storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _runQueryBody(List<(String, int)> rows) => jsonEncode([
      for (final (name, score) in rows)
        {
          'document': {
            'name': 'projects/qubble/databases/(default)/documents/'
                'leaderboard/uid-$name',
            'fields': {
              'name': {'stringValue': name},
              'score': {'integerValue': '$score'},
            },
          },
        },
      // runQuery may append a row without a document (readTime only).
      {'readTime': '2026-07-22T12:00:00Z'},
    ]);

Future<Storage> _storage([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  return Storage.create();
}

void main() {
  group('parseRunQueryResponse', () {
    test('parses rows, drops malformed ones, sorts descending', () {
      final entries = parseRunQueryResponse(_runQueryBody([
        ('Anna', 300),
        ('Ben', 900),
        ('C', 5), // invalid: name too short
      ]));
      expect(entries.map((e) => e.name), ['Ben', 'Anna']);
      expect(entries.first.score, 900);
    });

    test('tolerates junk input', () {
      expect(parseRunQueryResponse('{}'), isEmpty);
      expect(parseRunQueryResponse('[]'), isEmpty);
      expect(parseRunQueryResponse('[{"document":{}}]'), isEmpty);
    });

    test('rejects out-of-range scores and bad names', () {
      final entries = parseRunQueryResponse(_runQueryBody([
        ('Okay', 100),
        ('Cheater', 999999999), // > max
      ]));
      expect(entries.map((e) => e.name), ['Okay']);
    });
  });

  group('LeaderboardService.fetchTop', () {
    test('queries Firestore and parses the response', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'firestore.googleapis.com');
        expect(req.url.path, contains(':runQuery'));
        final query = jsonDecode(req.body)['structuredQuery'];
        expect(query['from'][0]['collectionId'], 'leaderboard');
        expect(query['orderBy'][0]['direction'], 'DESCENDING');
        return http.Response(_runQueryBody([('Anna', 300), ('Ben', 900)]), 200);
      });
      final service = LeaderboardService(client: client);
      final top = await service.fetchTop();
      expect(top.map((e) => e.name), ['Ben', 'Anna']);
    });

    test('throws on a non-200 response', () async {
      final client = MockClient((req) async => http.Response('nope', 404));
      final service = LeaderboardService(client: client);
      expect(service.fetchTop(), throwsA(isA<Exception>()));
    });
  });

  group('LeaderboardService.submit', () {
    test('signs up anonymously on first submit, persists identity, writes doc',
        () async {
      final storage = await _storage();
      final calls = <String>[];
      final client = MockClient((req) async {
        calls.add(req.url.host + req.url.path);
        if (req.url.host == 'identitytoolkit.googleapis.com') {
          return http.Response(
            jsonEncode({
              'localId': 'uid-123',
              'idToken': 'token-abc',
              'refreshToken': 'refresh-xyz',
            }),
            200,
          );
        }
        if (req.url.host == 'firestore.googleapis.com') {
          expect(req.method, 'PATCH');
          expect(req.url.path, endsWith('/leaderboard/uid-123'));
          expect(req.headers['Authorization'], 'Bearer token-abc');
          final fields = jsonDecode(req.body)['fields'];
          expect(fields['name']['stringValue'], 'Sam');
          expect(fields['score']['integerValue'], '1234');
          return http.Response('{}', 200);
        }
        fail('unexpected request: ${req.url}');
      });

      final service = LeaderboardService(client: client, storage: storage);
      final ok = await service.submit(name: 'Sam', score: 1234);
      expect(ok, isTrue);
      expect(storage.firebaseUid, 'uid-123');
      expect(storage.firebaseRefreshToken, 'refresh-xyz');
      expect(calls, hasLength(2)); // signUp + patch, no token refresh
    });

    test('reuses the stored identity via token refresh', () async {
      final storage = await _storage({
        'fbUid': 'uid-old',
        'fbRefreshToken': 'refresh-old',
      });
      final client = MockClient((req) async {
        if (req.url.host == 'securetoken.googleapis.com') {
          return http.Response(jsonEncode({'id_token': 'token-new'}), 200);
        }
        if (req.url.host == 'firestore.googleapis.com') {
          expect(req.url.path, endsWith('/leaderboard/uid-old'));
          expect(req.headers['Authorization'], 'Bearer token-new');
          return http.Response('{}', 200);
        }
        fail('unexpected request: ${req.url} (no signUp expected)');
      });

      final service = LeaderboardService(client: client, storage: storage);
      expect(await service.submit(name: 'Sam', score: 99), isTrue);
      expect(storage.firebaseUid, 'uid-old'); // identity kept
    });

    test('rejects invalid names/scores locally without any request', () async {
      final storage = await _storage();
      final client = MockClient((req) async => fail('no request expected'));
      final service = LeaderboardService(client: client, storage: storage);
      expect(await service.submit(name: 'x', score: 100), isFalse); // short
      expect(await service.submit(name: 'Sam!', score: 100), isFalse);
      expect(await service.submit(name: 'Sam', score: 0), isFalse);
      expect(
        await service.submit(name: 'Sam', score: kLeaderboardMaxScore + 1),
        isFalse,
      );
    });

    test('returns false when the rules reject the write (e.g. lower score)',
        () async {
      final storage = await _storage({
        'fbUid': 'uid-old',
        'fbRefreshToken': 'refresh-old',
      });
      final client = MockClient((req) async {
        if (req.url.host == 'securetoken.googleapis.com') {
          return http.Response(jsonEncode({'id_token': 't'}), 200);
        }
        return http.Response('{"error":{"status":"PERMISSION_DENIED"}}', 403);
      });
      final service = LeaderboardService(client: client, storage: storage);
      expect(await service.submit(name: 'Sam', score: 10), isFalse);
    });
  });
}
