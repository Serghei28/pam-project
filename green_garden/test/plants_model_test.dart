import 'package:flutter_test/flutter_test.dart';
import 'package:green_garden/data/mock_data.dart';
import 'package:green_garden/models/plants_model.dart';

import 'helpers.dart';

void main() {
  test('load: «грузится» → данные, с извещением подписчиков', () async {
    final model = PlantsModel(fastPlantRepo());
    var notifications = 0;
    model.addListener(() => notifications++);

    final loading = model.load();
    expect(model.isLoading, isTrue); // сразу после старта
    await loading;

    expect(model.isLoading, isFalse);
    expect(model.error, isNull);
    expect(model.plants, hasLength(mockPlants.length));
    expect(notifications, 2); // вход в «грузится» и выход из него
  });

  test('load при сбое сети: ошибка, а не пустой список молча', () async {
    final model = PlantsModel(fastPlantRepo()..simulateError = true);
    await model.load();
    expect(model.error, isNotNull);
    expect(model.plants, isEmpty);
  });

  test('список наружу только для чтения', () async {
    final model = PlantsModel(fastPlantRepo());
    await model.load();
    expect(() => model.plants.removeLast(), throwsUnsupportedError);
  });

  test('add добавляет растение с id от хранилища', () async {
    final model = PlantsModel(fastPlantRepo());
    await model.load();
    final error = await model.add(mockPlants.first.copyWith(id: 0));
    expect(error, isNull);
    expect(model.plants, hasLength(mockPlants.length + 1));
    expect(model.plants.last.id, isNot(0));
  });

  test('add при сбое возвращает текст ошибки и не меняет список', () async {
    final repo = fastPlantRepo();
    final model = PlantsModel(repo);
    await model.load();
    repo.simulateError = true;
    final error = await model.add(mockPlants.first.copyWith(id: 0));
    expect(error, isNotNull);
    expect(model.plants, hasLength(mockPlants.length));
  });

  test('remove убирает растение', () async {
    final model = PlantsModel(fastPlantRepo());
    await model.load();
    expect(await model.remove(1), isNull);
    expect(model.byId(1), isNull);
  });
}
