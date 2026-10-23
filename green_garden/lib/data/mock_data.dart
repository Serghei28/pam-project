import 'plant.dart';

// Только seed-данные. Даты считаются от сегодняшнего дня,
// поэтому статусы «полито / пора поливать» верны при любом запуске.
DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

final List<Plant> mockPlants = [
  Plant(
    id: 1,
    name: 'Монстера',
    species: 'Monstera deliciosa',
    wateringIntervalDays: 7,
    lastWateredAt: _daysAgo(0),
  ),
  Plant(
    id: 2,
    name: 'Фикус Бенджамина',
    species: 'Ficus benjamina',
    wateringIntervalDays: 5,
    lastWateredAt: _daysAgo(6),
  ),
  Plant(
    id: 3,
    name: 'Алоэ вера',
    species: 'Aloe vera',
    wateringIntervalDays: 14,
    lastWateredAt: _daysAgo(3),
  ),
  Plant(
    id: 4,
    name: 'Орхидея',
    species: 'Phalaenopsis',
    wateringIntervalDays: 7,
    lastWateredAt: _daysAgo(8),
  ),
  Plant(
    id: 5,
    name: 'Замиокулькас',
    species: 'Zamioculcas zamiifolia',
    wateringIntervalDays: 14,
    lastWateredAt: _daysAgo(1),
  ),
  Plant(
    id: 6,
    name: 'Сансевиерия',
    species: 'Sansevieria trifasciata',
    wateringIntervalDays: 14,
    lastWateredAt: _daysAgo(10),
  ),
  Plant(
    id: 7,
    name: 'Хлорофитум',
    species: 'Chlorophytum comosum',
    wateringIntervalDays: 5,
    lastWateredAt: _daysAgo(5),
  ),
  Plant(
    id: 8,
    name: 'Спатифиллум',
    species: 'Spathiphyllum wallisii',
    wateringIntervalDays: 4,
    lastWateredAt: _daysAgo(2),
  ),
];
