import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/weekend_event.dart';

void main() {
  test('active on Saturday and Sunday', () {
    expect(WeekendEvent.isActive(DateTime(2026, 7, 4)), isTrue); // Sat
    expect(WeekendEvent.isActive(DateTime(2026, 7, 5)), isTrue); // Sun
  });

  test('inactive on weekdays', () {
    for (var day = 6; day <= 10; day++) {
      // 2026-07-06 (Mon) .. 2026-07-10 (Fri)
      expect(WeekendEvent.isActive(DateTime(2026, 7, day)), isFalse);
    }
  });

  test('apply doubles on the weekend, leaves weekdays unchanged', () {
    expect(WeekendEvent.apply(50, DateTime(2026, 7, 4)), 100);
    expect(WeekendEvent.apply(50, DateTime(2026, 7, 6)), 50);
  });
}
