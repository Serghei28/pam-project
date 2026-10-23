// Доменная модель растения. Переживёт L5: mock_data.dart умрёт,
// а этот файл будут импортировать и mock, и http-репозиторий.
class Plant {
  final int id;
  final String name;
  final String species;
  final int wateringIntervalDays;
  final DateTime lastWateredAt;

  const Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.wateringIntervalDays,
    required this.lastWateredAt,
  });

  // Дата следующего полива = последний полив + интервал
  DateTime get nextWateringAt =>
      lastWateredAt.add(Duration(days: wateringIntervalDays));

  // Пора поливать, если срок следующего полива наступил (сегодня или раньше)
  bool needsWateringOn(DateTime day) =>
      !_dateOnly(nextWateringAt).isAfter(_dateOnly(day));

  bool get needsWatering => needsWateringOn(DateTime.now());

  // «То же растение, но с изменёнными полями» — нужно для create/update
  Plant copyWith({
    int? id,
    String? name,
    String? species,
    int? wateringIntervalDays,
    DateTime? lastWateredAt,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      lastWateredAt: lastWateredAt ?? this.lastWateredAt,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
