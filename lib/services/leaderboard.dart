/// Shared leaderboard: reads a public JSON file from the repo and submits new
/// scores as prefilled GitHub issues (a server-side Action validates them and
/// updates the file). The app never holds a GitHub token.
///
/// Read path works for everyone (public file, no auth). Submitting a score
/// needs a GitHub login, since GitHub requires auth to open an issue.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'feedback.dart' show FeedbackTarget, kFeedbackTarget;

/// One row on the leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({required this.name, required this.score});

  final String name;
  final int score;

  Map<String, dynamic> toJson() => {'name': name, 'score': score};
}

/// Parses the leaderboard JSON (`{"entries":[{"name","score"}, ...]}`),
/// dropping malformed rows and returning entries sorted by score descending.
List<LeaderboardEntry> parseLeaderboard(String body) {
  final decoded = jsonDecode(body);
  final rawEntries = decoded is Map<String, dynamic> ? decoded['entries'] : null;
  if (rawEntries is! List) return const [];

  final entries = <LeaderboardEntry>[];
  for (final e in rawEntries) {
    if (e is! Map) continue;
    final name = e['name'];
    final score = e['score'];
    if (name is String && name.isNotEmpty && score is num) {
      entries.add(LeaderboardEntry(name: name, score: score.toInt()));
    }
  }
  entries.sort((a, b) => b.score.compareTo(a.score));
  return entries;
}

/// Machine-readable marker the leaderboard Action parses out of the issue body.
/// Keep in sync with `.github/workflows/leaderboard.yaml`.
String scoreMarker(String name, int score) =>
    '<!-- qubble-score v1 name="$name" score="$score" -->';

/// Builds the prefilled "new issue" URL that submits [score] for [name].
/// Returns null for an empty name or non-positive score.
Uri? buildScoreIssueUri(
  String name,
  int score, {
  FeedbackTarget target = kFeedbackTarget,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty || score <= 0) return null;

  final body = StringBuffer()
    ..writeln('Neuer Highscore für die Qubble-Bestenliste 🏆')
    ..writeln()
    ..writeln('- Name: $trimmed')
    ..writeln('- Score: $score')
    ..writeln()
    ..writeln('Bitte einfach unten auf „Submit new issue" tippen.')
    ..writeln()
    ..writeln(scoreMarker(trimmed, score));

  return Uri.https('github.com', '/${target.owner}/${target.repo}/issues/new', {
    'labels': 'score',
    'title': 'Score: $trimmed — $score',
    'body': body.toString(),
  });
}

/// Reads the shared leaderboard from the public repo. Reads raw content from
/// the default branch, which reflects Action commits within minutes.
class LeaderboardService {
  LeaderboardService({
    http.Client? client,
    this.target = kFeedbackTarget,
    this.branch = 'main',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final FeedbackTarget target;
  final String branch;

  Uri get sourceUri => Uri.https(
        'raw.githubusercontent.com',
        '/${target.owner}/${target.repo}/$branch/leaderboard.json',
      );

  /// Fetches and parses the leaderboard. Throws on network/parse errors so the
  /// UI can show a retry state.
  Future<List<LeaderboardEntry>> fetchTop({int limit = 100}) async {
    // Cache-bust so an installed PWA doesn't serve a stale copy.
    final uri = sourceUri.replace(queryParameters: {
      't': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Leaderboard HTTP ${res.statusCode}');
    }
    final entries = parseLeaderboard(res.body);
    return entries.length > limit ? entries.sublist(0, limit) : entries;
  }
}
