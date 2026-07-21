/// Mandatory name entry shown on first launch. The name is the player's
/// identity on the shared leaderboard, so it can't be skipped.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key, required this.onSubmit, this.initial = ''});

  /// Called with the trimmed, validated name.
  final Future<void> Function(String name) onSubmit;

  /// Pre-fills the field (used when editing an existing name).
  final String initial;

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  String? _error;
  bool _saving = false;

  static const int _maxLen = 14;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Mindestens 2 Zeichen.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    await widget.onSubmit(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Qubble',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Wie heißt du? Dein Name erscheint in der Bestenliste.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GridColors.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: _maxLen,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Dein Name',
                    hintStyle: const TextStyle(color: GridColors.textMuted),
                    errorText: _error,
                    filled: true,
                    fillColor: GridColors.boardBackground,
                    counterStyle: const TextStyle(color: GridColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: GridColors.placed,
                    foregroundColor: GridColors.background,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Los geht’s',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
