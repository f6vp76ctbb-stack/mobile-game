/// Pure-Dart player-name validation + profanity screening. No Flutter imports.
///
/// The name is public (it shows on the shared leaderboard), so it is screened
/// for slurs and insults. Like most casual games this is a **local blocklist
/// with normalization** — it catches the obvious cases and common obfuscation
/// (leetspeak "n1gg3r", spaced "f u c k", elongated "fuuuck"), but it is not a
/// perfect moderation system (no server-side AI here by design). Keep the
/// lists conservative to avoid false positives on innocent names.
library;

class NameFilter {
  const NameFilter._();

  static const int minLength = 2;
  static const int maxLength = 14;

  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9 _\-]+$');

  /// Returns a German error message if [raw] is not an acceptable name, or
  /// null if it's fine. Covers length, allowed characters, and profanity.
  static String? problem(String raw) {
    final name = raw.trim();
    if (name.length < minLength) return 'Mindestens $minLength Zeichen.';
    if (name.length > maxLength) return 'Höchstens $maxLength Zeichen.';
    if (!_allowed.hasMatch(name)) {
      return 'Nur Buchstaben, Zahlen, Leerzeichen, _ und -.';
    }
    if (isOffensive(name)) return 'Bitte wähle einen anderen Namen.';
    return null;
  }

  static bool isAcceptable(String raw) => problem(raw) == null;

  /// Whether [raw] contains a blocked term (after normalization).
  static bool isOffensive(String raw) {
    final noCollapse = _normalize(raw, collapse: false);
    final collapsed = _normalize(raw, collapse: true);

    // Hard slurs: blocked anywhere in the string (catches "xXniggerXx").
    for (final w in _hardBlock) {
      if (noCollapse.contains(w) || collapsed.contains(w)) return true;
    }
    // Milder insults: only as a standalone token or the whole name, so
    // innocent names that merely contain the letters (e.g. "Cassie") pass.
    final tokens = <String>{
      noCollapse,
      collapsed,
      for (final t in raw.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
        _normalize(t, collapse: false),
      for (final t in raw.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
        _normalize(t, collapse: true),
    };
    for (final w in _wordBlock) {
      if (tokens.contains(w)) return true;
    }
    return false;
  }

  /// Lowercases, maps common leetspeak to letters, drops everything that isn't
  /// a-z, and (optionally) collapses runs of the same letter. Checking both the
  /// collapsed and non-collapsed forms catches both "fuuuck" and "assss".
  static String _normalize(String s, {required bool collapse}) {
    final lower = s.toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(_leet[ch] ?? ch);
    }
    var t = buf.toString().replaceAll(RegExp(r'[^a-z]'), '');
    if (collapse) {
      // Collapse runs of the same letter ("fuuuck" → "fuck"). Needs
      // replaceAllMapped — replaceAll does not expand $1 capture groups.
      t = t.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m.group(1)!);
    }
    return t;
  }

  static const Map<String, String> _leet = {
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '7': 't',
    '8': 'b',
    '9': 'g',
    '@': 'a',
    r'$': 's',
    '!': 'i',
    '+': 't',
  };

  // Content-moderation blocklists (normalized, letters only). Kept deliberately
  // small and unambiguous. `_hardBlock` = slurs blocked anywhere; `_wordBlock`
  // = insults blocked only as a whole token to avoid false positives.
  static const Set<String> _hardBlock = {
    // English slurs / strong profanity
    'nigger', 'nigga', 'faggot', 'retard', 'motherfucker',
    'whore', 'rapist', 'pedophile', 'nazi', 'hitler',
    'kike', 'chink',
    // German slurs / strong profanity
    'hurensohn', 'wichser', 'fotze', 'nutte', 'missgeburt', 'schwuchtel',
    'neger', 'judensau', 'vergewaltiger', 'kinderficker', 'spast', 'spasti',
  };

  static const Set<String> _wordBlock = {
    // English (token-matched to avoid false positives like "Scunthorpe")
    'fuck', 'shit', 'bitch', 'ass', 'asshole', 'dick', 'cock', 'pussy',
    'bastard', 'slut', 'penis', 'vagina', 'porn', 'cunt', 'rape', 'pedo',
    'spic', 'coon', 'nigga',
    // German
    'arsch', 'arschloch', 'scheisse', 'scheis', 'schlampe', 'hure', 'penner',
    'fick', 'ficker', 'ficken', 'schwanz', 'muschi',
  };
}
