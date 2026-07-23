import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/screens/home_screen.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:gridpop/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _homeApp() async {
  SharedPreferences.setMockInitialValues({'onboardingDone': true});
  final storage = await Storage.create();
  return ProviderScope(
    overrides: [storageProvider.overrideWithValue(storage)],
    child: MaterialApp(theme: buildGridTheme(), home: const HomeScreen()),
  );
}

void main() {
  testWidgets('home help opens the complete how-to guide', (tester) async {
    await tester.pumpWidget(await _homeApp());

    final helpButton = find.byTooltip('So spielst du Qubble');
    expect(helpButton, findsOneWidget);

    await tester.tap(helpButton);
    await tester.pumpAndSettle();

    expect(find.text('So spielst du Qubble'), findsOneWidget);
    expect(find.text('Ziehen & platzieren'), findsOneWidget);
    expect(find.text('Linien abräumen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.fling(find.byType(ListView), const Offset(0, -1200), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Sparschwein füllen'), findsOneWidget);
    expect(find.text('Verstanden'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Verstanden'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(helpButton, findsOneWidget);
  });
}
