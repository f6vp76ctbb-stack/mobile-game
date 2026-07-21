/// Pure-Dart helpers for the in-app feedback flow. No Flutter imports, so the
/// URL building is unit-testable.
///
/// The app can't write to GitHub directly (that would need a secret token,
/// which must never ship in a public web build). Instead feedback opens a
/// prefilled GitHub issue labelled `feedback`; a GitHub Action then appends it
/// to `FEEDBACK.md`. See `.github/workflows/feedback.yaml`.
library;

class FeedbackTarget {
  const FeedbackTarget({required this.owner, required this.repo});

  final String owner;
  final String repo;
}

/// The repository feedback issues are filed against.
const kFeedbackTarget = FeedbackTarget(
  owner: 'f6vp76ctbb-stack',
  repo: 'mobile-game',
);

/// Label the Action filters on. The GitHub issue URL prefills it; the label is
/// only actually applied when the submitter can label issues (the owner).
const kFeedbackLabel = 'feedback';

/// Builds the "new issue" URL that prefills the feedback [text], an optional
/// [context] block (app version, platform, profile) and the [kFeedbackLabel].
///
/// Returns null if [text] is blank so the UI can refuse empty submissions.
Uri? buildFeedbackIssueUri(
  String text, {
  FeedbackTarget target = kFeedbackTarget,
  Map<String, String> context = const {},
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  // Title: first line, clipped so the issue list stays readable.
  final firstLine = trimmed.split('\n').first.trim();
  final title = firstLine.length <= 60
      ? 'Feedback: $firstLine'
      : 'Feedback: ${firstLine.substring(0, 57)}…';

  final buffer = StringBuffer(trimmed);
  if (context.isNotEmpty) {
    buffer.writeln();
    buffer.writeln();
    buffer.writeln('---');
    context.forEach((k, v) => buffer.writeln('- $k: $v'));
  }

  return Uri.https('github.com', '/${target.owner}/${target.repo}/issues/new', {
    'labels': kFeedbackLabel,
    'title': title,
    'body': buffer.toString(),
  });
}
