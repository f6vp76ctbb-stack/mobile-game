import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/piece.dart';
import 'package:gridpop/monetization/ads.dart';
import 'package:gridpop/services/analytics.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/leaderboard.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/screens/game_screen.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:gridpop/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAds implements AdService {
  int rewardedCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showPrivacyOptions() async => false;

  @override
  Future<bool> showRewarded() async {
    rewardedCalls++;
    return true;
  }
}

class _RecordingLeaderboard extends LeaderboardService {
  final List<({String name, int score})> submissions = [];

  @override
  Future<bool> submit({required String name, required int score}) async {
    submissions.add((name: name, score: score));
    return true;
  }
}

GameController _controller(
  Storage storage, {
  AdService? ads,
  LeaderboardService? leaderboard,
}) {
  return GameController(
    storage,
    Haptics(enabled: false),
    SilentAudio(),
    ads ?? FakeAdService(),
    NoopAnalytics(),
    leaderboard: leaderboard,
  );
}

bool _placeOneLegalMove(GameController controller) {
  for (var slot = 0; slot < controller.state.tray.length; slot++) {
    if (controller.state.tray[slot] == null) continue;
    for (var row = 0; row < Board.size; row++) {
      for (var column = 0; column < Board.size; column++) {
        final cell = Cell(row, column);
        if (controller.canPlace(slot, cell)) {
          controller.place(slot, cell);
          return true;
        }
      }
    }
  }

  final rotationBudget = controller.state.rotationCharges.clamp(0, 3);
  for (var slot = 0; slot < controller.state.tray.length; slot++) {
    final piece = controller.state.tray[slot];
    if (piece == null) continue;
    var rotated = piece;
    for (var rotations = 1; rotations <= rotationBudget; rotations++) {
      rotated = rotated.rotatedCw();
      if (!controller.state.board.hasAnyPlacement(rotated)) continue;
      for (var i = 0; i < rotations; i++) {
        controller.rotateTray(slot);
      }
      return _placeOneLegalMove(controller);
    }
  }
  return false;
}

void _playToGameOver(GameController controller) {
  var guard = 0;
  while (!controller.state.gameOver && guard < 5000) {
    if (!_placeOneLegalMove(controller)) break;
    guard++;
  }
}

void main() {
  test('daily rejects all score-changing paid and rewarded helpers', () async {
    SharedPreferences.setMockInitialValues({
      'coins': 1000,
      'onboardingDone': true,
    });
    final storage = await Storage.create();
    final ads = _RecordingAds();
    final controller = _controller(storage, ads: ads);

    controller.startDaily(now: DateTime(2026, 7, 23));
    expect(_placeOneLegalMove(controller), isTrue);
    expect(controller.state.canUndo, isTrue);

    final boardBefore = controller.state.board.toAscii();
    final trayBefore = controller.state.tray.map((piece) => piece?.id).toList();
    final coinsBefore = controller.state.coins;

    expect(await controller.tryUndo(), isFalse);
    expect(await controller.trySwapPieces(), isFalse);
    expect(await controller.tryBomb(const Cell(4, 4)), isFalse);
    expect(await controller.reviveWithCoins(), isFalse);
    expect(await controller.luckyBlock(), isFalse);

    expect(controller.state.board.toAscii(), boardBefore);
    expect(
      controller.state.tray.map((piece) => piece?.id).toList(),
      trayBefore,
    );
    expect(controller.state.coins, coinsBefore);
    expect(ads.rewardedCalls, 0);
  });

  test('daily score does not become an endless highscore or upload', () async {
    SharedPreferences.setMockInitialValues({
      'playerName': 'DailyPlayer',
      'onboardingDone': true,
    });
    final storage = await Storage.create();
    final leaderboard = _RecordingLeaderboard();
    final controller = _controller(storage, leaderboard: leaderboard);

    controller.startDaily(now: DateTime(2026, 7, 23));
    _playToGameOver(controller);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.state.gameOver, isTrue);
    expect(controller.state.score, greaterThan(0));
    expect(controller.state.isNewHighscore, isFalse);
    expect(storage.highscore, 0);
    expect(leaderboard.submissions, isEmpty);
  });

  testWidgets('daily UI hides Lucky, coin boosters and revive', (tester) async {
    SharedPreferences.setMockInitialValues({
      'coins': 1000,
      'onboardingDone': true,
    });
    final storage = await Storage.create();
    final container = ProviderContainer(
      overrides: [storageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    container
        .read(gameControllerProvider.notifier)
        .startDaily(now: DateTime(2026, 7, 23));

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildGridTheme(), home: const GameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neue Teile (Video)'), findsNothing);
    expect(find.text('Undo'), findsNothing);
    expect(find.text('Tausch'), findsNothing);
    expect(find.text('Bombe'), findsNothing);
    expect(find.text('Drehen'), findsNothing);
  });
}
