class Plant {
  final int id;
  final String name;
  final String species;
  final int wateringIntervalDays;
  final String lastWatered;
  final bool isWatered;

  const Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.wateringIntervalDays,
    required this.lastWatered,
    required this.isWatered,
  });
}

const List<Plant> mockPlants = [
  Plant(
    id: 1,
    name: 'Монстера',
    species: 'Monstera deliciosa',
    wateringIntervalDays: 7,
    lastWatered: 'Сегодня',
    isWatered: true,
  ),
  Plant(
    id: 2,
    name: 'Фикус Бенджамина',
    species: 'Ficus benjamina',
    wateringIntervalDays: 5,
    lastWatered: '6 дней назад',
    isWatered: false,
  ),
  Plant(
    id: 3,
    name: 'Алоэ вера',
    species: 'Aloe vera',
    wateringIntervalDays: 14,
    lastWatered: '3 дня назад',
    isWatered: true,
  ),
  Plant(
    id: 4,
    name: 'Орхидея',
    species: 'Phalaenopsis',
    wateringIntervalDays: 7,
    lastWatered: '8 дней назад',
    isWatered: false,
  ),
  Plant(
    id: 5,
    name: 'Замиокулькас',
    species: 'Zamioculcas zamiifolia',
    wateringIntervalDays: 14,
    lastWatered: 'Вчера',
    isWatered: true,
  ),
  Plant(
    id: 6,
    name: 'Сансевиерия',
    species: 'Sansevieria trifasciata',
    wateringIntervalDays: 14,
    lastWatered: '10 дней назад',
    isWatered: true,
  ),
  Plant(
    id: 7,
    name: 'Хлорофитум',
    species: 'Chlorophytum comosum',
    wateringIntervalDays: 5,
    lastWatered: '5 дней назад',
    isWatered: false,
  ),
  Plant(
    id: 8,
    name: 'Спатифиллум',
    species: 'Spathiphyllum wallisii',
    wateringIntervalDays: 4,
    lastWatered: '2 дня назад',
    isWatered: true,
  ),
];