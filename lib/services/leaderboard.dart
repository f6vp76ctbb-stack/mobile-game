/// Shared leaderboard on Firestore — account-free by design.
///
/// Reads the top list via the public Firestore REST API and submits scores
/// under a silent anonymous Firebase-Auth identity (created lazily on the
/// first submit; players never see any login UI). Pure Dart + http, so it
/// behaves identically on native and web and is fully unit-testable with a
/// fake client. Server-side enforcement lives in `firebase/firestore.rules`.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'firebase_config.dart';
import 'storage.dart';

/// One row on the leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({required this.name, required this.score});

  final String name;
  final int score;
}

/// Client-side mirror of the Firestore security rules (the rules are the
/// actual gate; this just avoids pointless requests).
final RegExp kLeaderboardNameRule = RegExp(r'^[A-Za-z0-9 _-]{2,14}$');
const int kLeaderboardMaxScore = 100000000;

/// Parses a Firestore `runQuery` REST response (a JSON array of rows with an
/// optional `document`), dropping malformed rows; sorted by score descending.
List<LeaderboardEntry> parseRunQueryResponse(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! List) return const [];

  final entries = <LeaderboardEntry>[];
  for (final row in decoded) {
    if (row is! Map) continue;
    final document = row['document'];
    if (document is! Map) continue;
    final fields = document['fields'];
    if (fields is! Map) continue;

    final name = _stringField(fields, 'name');
    final score = _intField(fields, 'score');
    if (name != null &&
        kLeaderboardNameRule.hasMatch(name) &&
        score != null &&
        score > 0 &&
        score <= kLeaderboardMaxScore) {
      entries.add(LeaderboardEntry(name: name, score: score));
    }
  }
  entries.sort((a, b) => b.score.compareTo(a.score));
  return entries;
}

String? _stringField(Map<dynamic, dynamic> fields, String key) {
  final field = fields[key];
  if (field is! Map) return null;
  final value = field['stringValue'];
  return value is String ? value : null;
}

int? _intField(Map<dynamic, dynamic> fields, String key) {
  final field = fields[key];
  if (field is! Map) return null;
  // Firestore REST encodes integerValue as a string.
  final value = field['integerValue'];
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}

/// Firestore-backed leaderboard client.
class LeaderboardService {
  LeaderboardService({
    http.Client? client,
    this.storage,
    this.projectId = FirebaseConfig.projectId,
    this.apiKey = FirebaseConfig.apiKey,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Needed only for submitting (persists the anonymous identity); reading
  /// works without it.
  final Storage? storage;

  final String projectId;
  final String apiKey;

  static const _firestoreHost = 'firestore.googleapis.com';
  static const _collection = 'leaderboard';

  String get _documentsPath =>
      '/v1/projects/$projectId/databases/(default)/documents';

  /// Fetches the top [limit] entries. Throws on network/HTTP errors so the
  /// UI can show its retry state.
  Future<List<LeaderboardEntry>> fetchTop({int limit = 50}) async {
    final uri = Uri.https(_firestoreHost, '$_documentsPath:runQuery', {
      'key': apiKey,
    });
    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': _collection},
          ],
          'orderBy': [
            {
              'field': {'fieldPath': 'score'},
              'direction': 'DESCENDING',
            },
          ],
          'limit': limit,
        },
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Leaderboard HTTP ${res.statusCode}');
    }
    return parseRunQueryResponse(res.body);
  }

  /// Submits the player's best score under their silent anonymous identity.
  /// Returns true on success; returns false (never throws) on any failure —
  /// offline play must degrade quietly. The security rules reject lowering
  /// an existing score.
  Future<bool> submit({required String name, required int score}) async {
    final trimmed = name.trim();
    if (!kLeaderboardNameRule.hasMatch(trimmed) ||
        score <= 0 ||
        score > kLeaderboardMaxScore) {
      return false;
    }
    try {
      final identity = await _ensureIdentity();
      if (identity == null) return false;

      final uri = Uri.https(
        _firestoreHost,
        '$_documentsPath/$_collection/${identity.uid}',
        {'key': apiKey},
      );
      final res = await _client.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${identity.idToken}',
        },
        body: jsonEncode({
          'fields': {
            'name': {'stringValue': trimmed},
            'score': {'integerValue': '$score'},
          },
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Returns a usable anonymous identity: refreshes the stored one, or signs
  /// up a fresh anonymous user on first use (or when the token was revoked).
  Future<({String uid, String idToken})?> _ensureIdentity() async {
    final storage = this.storage;
    if (storage == null) return null;

    final uid = storage.firebaseUid;
    final refreshToken = storage.firebaseRefreshToken;
    if (uid != null && refreshToken != null) {
      final res = await _client.post(
        Uri.https('securetoken.googleapis.com', '/v1/token', {'key': apiKey}),
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final idToken = data is Map ? data['id_token'] : null;
        if (idToken is String) return (uid: uid, idToken: idToken);
      }
      // Fall through: token revoked/expired — start a fresh identity.
    }

    final res = await _client.post(
      Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:signUp', {
        'key': apiKey,
      }),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'returnSecureToken': true}),
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data is! Map) return null;
    final localId = data['localId'];
    final idToken = data['idToken'];
    final newRefresh = data['refreshToken'];
    if (localId is! String || idToken is! String || newRefresh is! String) {
      return null;
    }
    await storage.setFirebaseIdentity(uid: localId, refreshToken: newRefresh);
    return (uid: localId, idToken: idToken);
  }
}
