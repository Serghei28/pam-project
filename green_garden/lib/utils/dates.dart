// Форматирование дат для экранов (без пакета intl).
// Параметр now нужен для unit-тестов; в приложении он не передаётся.

import 'calendar.dart';

const _months = [
  'янв.', 'февр.', 'мар.', 'апр.', 'мая', 'июн.',
  'июл.', 'авг.', 'сент.', 'окт.', 'нояб.', 'дек.',
];

// 14 окт. 2026
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

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
int daysFromToday(DateTime date, {DateTime? now}) =>
    daysBetween(now ?? DateTime.now(), date);

// Сегодня / Вчера / 6 дн. назад
String daysAgoText(DateTime date, {DateTime? now}) {
  final days = -daysFromToday(date, now: now);
  if (days == 0) return 'Сегодня';
  if (days == 1) return 'Вчера';
  if (days > 1) return '$days дн. назад';
  return formatDate(date); // дата в будущем
}

// Срок для напоминания: Просрочено / Сегодня / Завтра / дата
String dueText(DateTime due, {DateTime? now}) {
  final days = daysFromToday(due, now: now);
  if (days < 0) return 'Просрочено: ${formatDate(due)}';
  if (days == 0) return 'Сегодня, ${formatDate(due)}';
  if (days == 1) return 'Завтра, ${formatDate(due)}';
  return formatDate(due);
}
