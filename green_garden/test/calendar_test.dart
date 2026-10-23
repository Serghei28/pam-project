import 'package:flutter_test/flutter_test.dart';
import 'package:green_garden/utils/calendar.dart';

void main() {
  group('daysBetween', () {
    test('считает календарные дни, а не 24-часовые отрезки', () {
      // 23:00 → 01:00 следующего дня: всего 2 часа, но это 1 день
      expect(
        daysBetween(DateTime(2026, 10, 23, 23), DateTime(2026, 10, 24, 1)),
        1,
      );
    });

    test('ночь перевода часов (25 окт. 2026) не ломает счёт', () {
      expect(daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 26)), 2);
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    });

    test('отрицательно, если вторая дата раньше', () {
      expect(daysBetween(DateTime(2026, 10, 23), DateTime(2026, 10, 20)), -3);
    });
  });

  group('addDays', () {
    test('переносит месяц и год', () {
      expect(addDays(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 1));
      expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
    });

    test('через ночь перевода часов остаётся полночь', () {
      expect(addDays(DateTime(2026, 10, 24), 2), DateTime(2026, 10, 26));
    });
  });
}
