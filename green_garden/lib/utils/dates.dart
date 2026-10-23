// Форматирование дат для экранов (без пакета intl)

const _months = [
  'янв.', 'февр.', 'мар.', 'апр.', 'мая', 'июн.',
  'июл.', 'авг.', 'сент.', 'окт.', 'нояб.', 'дек.',
];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// 14 окт. 2026
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

// Сегодня / Вчера / 6 дн. назад
String daysAgoText(DateTime date) {
  final days =
      _dateOnly(DateTime.now()).difference(_dateOnly(date)).inDays;
  if (days == 0) return 'Сегодня';
  if (days == 1) return 'Вчера';
  if (days > 1) return '$days дн. назад';
  return formatDate(date); // дата в будущем
}
