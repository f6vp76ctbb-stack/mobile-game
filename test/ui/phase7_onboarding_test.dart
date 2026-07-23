import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/coach_hints.dart';
import 'package:gridpop/game/generator.dart';
import 'package:gridpop/monetization/ads.dart';
import 'package:gridpop/services/analytics.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(GameController, Storage)> _controller(
  Map<String, Object> preferences,
) async {
  SharedPreferences.setMockInitialValues(preferences);
  final storage = await Storage.create();
  return (
    GameController(
      storage,
      Haptics(enabled: false),
      SilentAudio(),
      FakeAdService(),
      NoopAnalytics(),
    ),
    storage,
  );
}

void main() {
  group('first-run fairness phase', () {
    test(
      'first endless run extends early weighting to 20 placements',
      () async {
        final (controller, _) = await _controller({});

        controller.newGame(seed: 7);

        expect(
          controller.earlyPhaseMovesForTest,
          GameController.firstRunEarlyPhaseMoves,
        );
        expect(GameController.firstRunEarlyPhaseMoves, 20);
      },
    );

    test('returning players use the regular 10-placement phase', () async {
      final (controller, _) = await _controller({
        'lifetimeStats': '{"games":1}',
      });

      controller.newGame(seed: 7);

      expect(
        controller.earlyPhaseMovesForTest,
        PieceGenerator.defaultEarlyPhaseMoves,
      );
      expect(PieceGenerator.defaultEarlyPhaseMoves, 10);
    });

    test('daily challenge always keeps the standard fairness phase', () async {
      final (controller, _) = await _controller({});

      controller.startDaily(now: DateTime(2026, 7, 23));

      expect(
        controller.earlyPhaseMovesForTest,
        PieceGenerator.defaultEarlyPhaseMoves,
      );
    });
  });

  group('contextual coach hints', () {
    test(
      'shows the affordable-booster hint only once and persists it',
      () async {
        final (controller, storage) = await _controller({
          'onboardingDone': true,
          'coins': 100,
        });

        controller.newGame(seed: 3);

        expect(controller.state.contextualHint, contains('Booster'));
        expect(storage.seenCoachHints, contains(CoachHintType.booster));

        controller.newGame(seed: 4);
        expect(controller.state.contextualHint, isNull);
      },
    );

    test('rotation queues and persists its contextual hint', () async {
      final (controller, storage) = await _controller({'onboardingDone': true});
      controller.newGame(seed: 3);

      expect(controller.rotateTray(0), isTrue);

      expect(controller.state.contextualHint, contains('Drehen'));
      expect(storage.seenCoachHints, contains(CoachHintType.rotation));
    });

    test('daily challenge suppresses the booster coach hint', () async {
      final (controller, storage) = await _controller({
        'onboardingDone': true,
        'coins': 100,
      });

      controller.startDaily(now: DateTime(2026, 7, 23));

      expect(controller.state.contextualHint, isNull);
      expect(storage.seenCoachHints, isNot(contains(CoachHintType.booster)));
    });
  });
}
