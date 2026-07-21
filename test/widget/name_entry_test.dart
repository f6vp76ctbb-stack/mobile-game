import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/ui/screens/name_entry_screen.dart';

void main() {
  testWidgets('submits a valid name', (tester) async {
    String? saved;
    await tester.pumpWidget(MaterialApp(
      home: NameEntryScreen(onSubmit: (n) async => saved = n),
    ));

    await tester.enterText(find.byType(TextField), '  Max  ');
    await tester.tap(find.text('Los geht’s'));
    await tester.pump();

    expect(saved, 'Max');
  });

  testWidgets('rejects a too-short name', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: NameEntryScreen(onSubmit: (n) async => calls++),
    ));

    await tester.enterText(find.byType(TextField), 'M');
    await tester.tap(find.text('Los geht’s'));
    await tester.pump();

    expect(calls, 0);
    expect(find.text('Mindestens 2 Zeichen.'), findsOneWidget);
  });
}
