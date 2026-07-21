import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/screens/game_screen.dart';
import 'package:gridpop/ui/screens/home_screen.dart';
import 'package:gridpop/ui/screens/puzzle_screen.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:gridpop/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _app(Widget home) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await Storage.create();
  return ProviderScope(
    overrides: [storageProvider.overrideWithValue(storage)],
    child: MaterialApp(theme: buildGridTheme(), home: home),
  );
}

void main() {
  testWidgets('home screen shows title and play button', (tester) async {
    await tester.pumpWidget(await _app(const HomeScreen()));
    expect(find.text('Qubble'), findsOneWidget);
    expect(find.text('Spielen'), findsOneWidget);
    expect(find.text('BESTWERT'), findsOneWidget);
  });

  testWidgets('tapping Spielen navigates into the game', (tester) async {
    await tester.pumpWidget(await _app(const HomeScreen()));
    await tester.tap(find.text('Spielen'));
    await tester.pumpAndSettle();
    // The game header shows the score label.
    expect(find.text('PUNKTE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
  });

  testWidgets('game screen renders board and tray without overflow',
      (tester) async {
    await tester.pumpWidget(await _app(const GameScreen()));
    await tester.pumpAndSettle();
    expect(find.text('PUNKTE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('puzzle screen loads a level and renders', (tester) async {
    await tester.pumpWidget(await _app(const PuzzleScreen(level: 0)));
    await tester.pumpAndSettle();
    expect(find.text('Rätsel 1'), findsOneWidget);
    expect(find.textContaining('Ziel:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
