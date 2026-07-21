import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/screens/skins_screen.dart';
import 'package:gridpop/ui/screens/themes_screen.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:gridpop/ui/theme.dart';
import 'package:gridpop/ui/widgets/mini_board_preview.dart';
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
  testWidgets('themes screen shows a mini board preview per theme',
      (tester) async {
    await tester.pumpWidget(await _app(const ThemesScreen()));
    await tester.pumpAndSettle();
    // ListView builds lazily, so only the visible tiles exist in the test
    // viewport — assert previews are present, not the full catalog count.
    expect(find.byType(MiniBoardPreview), findsAtLeastNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('skins screen shows a mini board preview per skin',
      (tester) async {
    await tester.pumpWidget(await _app(const SkinsScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(MiniBoardPreview), findsAtLeastNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
