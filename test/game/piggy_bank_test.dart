import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/piggy_bank.dart';

void main() {
  test('starts empty at base capacity', () {
    final p = PiggyBank.initial();
    expect(p.coins, 0);
    expect(p.capacity, PiggyBank.baseCapacity);
    expect(p.isEmpty, isTrue);
    expect(p.showHint, isFalse);
  });

  test('addLines accumulates one coin per line', () {
    final p = PiggyBank.initial().addLines(3).addLines(2);
    expect(p.coins, 5);
  });

  test('fill is capped at capacity', () {
    final p = PiggyBank.initial().addLines(999);
    expect(p.coins, PiggyBank.baseCapacity); // 500
    expect(p.fillFraction, 1.0);
  });

  test('hint shows only at/above 80% full', () {
    final almost = PiggyBank.initial().addLines(399); // 79.8%
    expect(almost.showHint, isFalse);
    final full = PiggyBank.initial().addLines(400); // 80%
    expect(full.showHint, isTrue);
  });

  test('opening empties the bank and raises capacity by a step', () {
    final filled = PiggyBank.initial().addLines(500);
    final opened = filled.opened();
    expect(opened.coins, 0);
    expect(opened.capacity, PiggyBank.baseCapacity + PiggyBank.capacityStep);
  });

  test('capacity never exceeds the maximum', () {
    var p = PiggyBank.initial();
    for (var i = 0; i < 20; i++) {
      p = p.opened();
    }
    expect(p.capacity, PiggyBank.maxCapacity);
  });
}
