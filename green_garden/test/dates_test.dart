import 'package:flutter_test/flutter_test.dart';
import 'package:green_garden/utils/dates.dart';

void main() {
  final now = DateTime(2026, 10, 23, 19, 0);

  test('formatDate и formatDateTime', () {
    expect(formatDate(DateTime(2026, 10, 14)), '14 окт. 2026');
    expect(formatDateTime(DateTime(2026, 1, 5, 9, 5)), '5 янв. 2026, 09:05');
  });

  test('daysAgoText', () {
    expect(daysAgoText(DateTime(2026, 10, 23, 8), now: now), 'Сегодня');
    expect(daysAgoText(DateTime(2026, 10, 22, 23), now: now), 'Вчера');
    expect(daysAgoText(DateTime(2026, 10, 17), now: now), '6 дн. назад');
  });

  test('dueText', () {
    expect(
      dueText(DateTime(2026, 10, 22), now: now),
      'Просрочено: 22 окт. 2026',
    );
    expect(dueText(DateTime(2026, 10, 23), now: now), 'Сегодня, 23 окт. 2026');
    expect(dueText(DateTime(2026, 10, 24), now: now), 'Завтра, 24 окт. 2026');
    expect(dueText(DateTime(2026, 10, 30), now: now), '30 окт. 2026');
  });
}
