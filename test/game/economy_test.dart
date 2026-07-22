import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/economy.dart';

void main() {
  test('gold cost scales with the diamond count', () {
    expect(Economy.goldCostForDiamonds(1), Economy.goldPerDiamond);
    expect(Economy.goldCostForDiamonds(10), 10 * Economy.goldPerDiamond);
    expect(Economy.goldCostForDiamonds(0), 0);
    expect(Economy.goldCostForDiamonds(-5), 0);
  });
}
