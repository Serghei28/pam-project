import '../utils/calendar.dart';

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

  // Дата следующего полива = дата последнего полива + интервал (в днях)
  DateTime get nextWateringAt => addDays(lastWateredAt, wateringIntervalDays);

  // Пора поливать, если срок следующего полива наступил (сегодня или раньше)
  bool needsWateringOn(DateTime day) => daysBetween(day, nextWateringAt) <= 0;

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
}
