import 'package:flutter_test/flutter_test.dart';
import 'package:green_garden/data/plant.dart';

void main() {
  final plant = Plant(
    id: 1,
    name: 'Фикус',
    species: 'Ficus benjamina',
    wateringIntervalDays: 5,
    lastWateredAt: DateTime(2026, 10, 20, 18, 30),
  );

  test('следующий полив = дата последнего полива + интервал', () {
    expect(plant.nextWateringAt, DateTime(2026, 10, 25));
  });

  test('статус «пора поливать» считается по датам, без учёта часов', () {
    expect(plant.needsWateringOn(DateTime(2026, 10, 24, 23, 59)), isFalse);
    expect(plant.needsWateringOn(DateTime(2026, 10, 25, 0, 1)), isTrue);
    expect(plant.needsWateringOn(DateTime(2026, 10, 30)), isTrue);
  });

  test('copyWith меняет только переданные поля', () {
    final copy = plant.copyWith(id: 1000);
    expect(copy.id, 1000);
    expect(copy.name, plant.name);
    expect(copy.lastWateredAt, plant.lastWateredAt);
  });
}
