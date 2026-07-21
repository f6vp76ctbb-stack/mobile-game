import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/ui/screens/feedback_screen.dart';

void main() {
  testWidgets('submitting launches a prefilled feedback issue URL',
      (tester) async {
    Uri? launched;
    await tester.pumpWidget(MaterialApp(
      home: FeedbackScreen(
        launcher: (uri) async {
          launched = uri;
          return true;
        },
      ),
    ));

    await tester.enterText(find.byType(TextField), 'Bombe ruckelt');
    await tester.tap(find.text('Feedback senden'));
    await tester.pump();

    expect(launched, isNotNull);
    expect(launched!.host, 'github.com');
    expect(launched!.queryParameters['body'], contains('Bombe ruckelt'));
    expect(launched!.queryParameters['labels'], 'feedback');
  });

  testWidgets('blank feedback does not launch anything', (tester) async {
    var launchCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: FeedbackScreen(
        launcher: (uri) async {
          launchCount++;
          return true;
        },
      ),
    ));

    await tester.tap(find.text('Feedback senden'));
    await tester.pump();

    expect(launchCount, 0);
    expect(find.text('Bitte zuerst etwas eintippen.'), findsOneWidget);
  });
}
