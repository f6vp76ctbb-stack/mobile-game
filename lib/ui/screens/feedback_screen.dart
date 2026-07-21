/// In-app feedback: type a note, submit it as a prefilled GitHub issue.
///
/// A GitHub Action appends each feedback issue to `FEEDBACK.md`, which we read
/// later as a source of improvement ideas. The app never holds a GitHub token
/// (public build) — it only opens the issue composer in the browser.
library;

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/feedback.dart';
import '../theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, this.launcher});

  /// Injectable URL launcher for tests; defaults to url_launcher.
  final Future<bool> Function(Uri uri)? launcher;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _launch(Uri uri) {
    final launcher = widget.launcher;
    if (launcher != null) return launcher(uri);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    final uri = buildFeedbackIssueUri(
      _controller.text,
      context: {
        'Plattform': kIsWeb ? 'Web/PWA' : defaultTargetPlatform.name,
      },
    );
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst etwas eintippen.')),
      );
      return;
    }

    setState(() => _sending = true);
    final ok = await _launch(uri);
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Danke! Schick das Issue auf GitHub ab.'),
        ),
      );
      Navigator.of(context).maybePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GitHub ließ sich nicht öffnen. Später erneut versuchen.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: GridColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Was gefällt dir, was nervt, was fehlt? Dein Feedback landet als '
              'GitHub-Issue und hilft direkt bei der Weiterentwicklung.',
              style: TextStyle(color: GridColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(color: GridColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Dein Feedback…',
                  hintStyle: const TextStyle(color: GridColors.textMuted),
                  filled: true,
                  fillColor: GridColors.boardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Es öffnet sich GitHub — dort noch auf „Submit new issue" tippen. '
              '(Einmaliger GitHub-Login nötig.)',
              style: TextStyle(color: GridColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Feedback senden'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: GridColors.placed,
                foregroundColor: GridColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
