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

// 09:05
String formatTime(DateTime date) {
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

// 14 окт. 2026, 09:05
String formatDateTime(DateTime date) =>
    '${formatDate(date)}, ${formatTime(date)}';

// Сколько дней от сегодня до даты: 0 — сегодня, -1 — вчера, 1 — завтра
int daysFromToday(DateTime date) =>
    _dateOnly(date).difference(_dateOnly(DateTime.now())).inDays;

// Срок для напоминания: Просрочено / Сегодня / Завтра / дата
String dueText(DateTime due) {
  final days = daysFromToday(due);
  if (days < 0) return 'Просрочено: ${formatDate(due)}';
  if (days == 0) return 'Сегодня, ${formatDate(due)}';
  if (days == 1) return 'Завтра, ${formatDate(due)}';
  return formatDate(due);
}
