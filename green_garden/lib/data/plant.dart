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

  // Граница JSON (L5). Сервер хранит время в UTC (ISO-8601), а расчёт
  // дней в приложении — в местном времени, поэтому .toLocal().
  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
    id: j['id'] as int,
    name: j['name'] as String,
    species: j['species'] as String? ?? '',
    wateringIntervalDays: (j['wateringIntervalDays'] as num).toInt(),
    lastWateredAt: DateTime.parse(j['lastWateredAt'] as String).toLocal(),
  );

  // Без id — идентичность даёт сервер (C8)
  Map<String, dynamic> toJson() => {
    'name': name,
    'species': species,
    'wateringIntervalDays': wateringIntervalDays,
    'lastWateredAt': lastWateredAt.toUtc().toIso8601String(),
  };

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
