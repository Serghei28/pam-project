import 'plant.dart';
import 'reminder.dart';
import 'watering_log.dart';

// Только seed-данные. Даты считаются от сегодняшнего дня,
// поэтому статусы «полито / пора поливать» верны при любом запуске.
// Дни считаются через DateTime(y, m, d ± n) — без ошибок перевода часов.

// days дней назад, в указанное время
DateTime _daysAgoAt(int days, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - days, hour, minute);
}

// через days дней (отрицательное число — в прошлом)
DateTime _inDays(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days, 9, 0);
}

final List<Plant> mockPlants = [
  Plant(
    id: 1,
    name: 'Монстера',
    species: 'Monstera deliciosa',
    wateringIntervalDays: 7,
    lastWateredAt: _daysAgoAt(0, 9, 0),
  ),
  Plant(
    id: 2,
    name: 'Фикус Бенджамина',
    species: 'Ficus benjamina',
    wateringIntervalDays: 5,
    lastWateredAt: _daysAgoAt(6, 8, 45),
  ),
  Plant(
    id: 3,
    name: 'Алоэ вера',
    species: 'Aloe vera',
    wateringIntervalDays: 14,
    lastWateredAt: _daysAgoAt(3, 10, 15),
  ),
  Plant(
    id: 4,
    name: 'Орхидея',
    species: 'Phalaenopsis',
    wateringIntervalDays: 7,
    lastWateredAt: _daysAgoAt(8, 19, 0),
  ),
  Plant(
    id: 5,
    name: 'Замиокулькас',
    species: 'Zamioculcas zamiifolia',
    wateringIntervalDays: 14,
    lastWateredAt: _daysAgoAt(1, 18, 30),
  ),
  Plant(
    id: 6,
    name: 'Сансевиерия',
    species: 'Sansevieria trifasciata',
    wateringIntervalDays: 14,
    lastWateredAt: _daysAgoAt(10, 12, 0),
  ),
  Plant(
    id: 7,
    name: 'Хлорофитум',
    species: 'Chlorophytum comosum',
    wateringIntervalDays: 5,
    lastWateredAt: _daysAgoAt(5, 9, 30),
  ),
  Plant(
    id: 8,
    name: 'Спатифиллум',
    species: 'Spathiphyllum wallisii',
    wateringIntervalDays: 4,
    lastWateredAt: _daysAgoAt(2, 8, 45),
  ),
];

// Журнал полива. Последняя запись каждого растения совпадает
// с его lastWateredAt (дата и время).

final List<WateringLog> mockWateringLogs = [
  WateringLog(
    id: 1,
    plantId: 1,
    date: _daysAgoAt(0, 9, 0),
    note: 'Земля была сухая',
  ),
  WateringLog(
    id: 2,
    plantId: 5,
    date: _daysAgoAt(1, 18, 30),
    note: 'Немного, как обычно',
  ),
  WateringLog(
    id: 3,
    plantId: 8,
    date: _daysAgoAt(2, 8, 45),
    note: 'Листья немного поникли',
  ),
  WateringLog(
    id: 4,
    plantId: 3,
    date: _daysAgoAt(3, 10, 15),
    note: 'Совсем чуть-чуть',
  ),
  WateringLog(
    id: 5,
    plantId: 7,
    date: _daysAgoAt(5, 9, 30),
    note: 'Опрыскала листья',
  ),
  WateringLog(
    id: 6,
    plantId: 2,
    date: _daysAgoAt(6, 8, 45),
    note: 'Листья слегка опали',
  ),
  WateringLog(
    id: 7,
    plantId: 1,
    date: _daysAgoAt(7, 9, 15),
    note: 'Полила в обычном режиме',
  ),
  WateringLog(
    id: 8,
    plantId: 4,
    date: _daysAgoAt(8, 19, 0),
    note: 'Полив погружением',
  ),
  WateringLog(
    id: 9,
    plantId: 6,
    date: _daysAgoAt(10, 12, 0),
    note: 'Добавила подкормку',
  ),
  WateringLog(
    id: 10,
    plantId: 1,
    date: _daysAgoAt(14, 8, 50),
    note: 'Добавила подкормку',
  ),
];

// Напоминания об уходе (кроме полива — его срок считается из интервала).
// Отрицательное число дней — срок уже прошёл.

final List<Reminder> mockReminders = [
  Reminder(
    id: 1,
    plantId: 1,
    type: ReminderType.wipeLeaves,
    dueDate: _inDays(3),
  ),
  Reminder(
    id: 2,
    plantId: 5,
    type: ReminderType.fertilize,
    dueDate: _inDays(5),
  ),
  Reminder(
    id: 3,
    plantId: 4,
    type: ReminderType.repot,
    dueDate: _inDays(12),
  ),
  Reminder(
    id: 4,
    plantId: 2,
    type: ReminderType.spray,
    dueDate: _inDays(-1),
  ),
  Reminder(
    id: 5,
    plantId: 8,
    type: ReminderType.spray,
    dueDate: _inDays(1),
  ),
  Reminder(
    id: 6,
    plantId: 3,
    type: ReminderType.fertilize,
    dueDate: _inDays(-3),
    isDone: true,
  ),
  Reminder(
    id: 7,
    plantId: 6,
    type: ReminderType.wipeLeaves,
    dueDate: _inDays(-5),
    isDone: true,
  ),
];
