import 'package:flutter_test/flutter_test.dart';
import 'package:green_garden/models/plants_model.dart';

import 'fakes/mock_data.dart';
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

  // ---- L5: поиск и пагинация ----

  // Хранилище с seed (8) + extra растений — чтобы было больше одной страницы
  Future<PlantsModel> modelWithPlants(int extra) async {
    final repo = fastPlantRepo();
    for (var i = 0; i < extra; i++) {
      await repo.create(mockPlants.first.copyWith(id: 0, name: 'Кактус $i'));
    }
    return PlantsModel(repo);
  }

  test('load(search:) отдаёт фильтр хранилищу и помнит его для retry',
      () async {
    final model = PlantsModel(fastPlantRepo());
    await model.load(search: 'алоэ');
    expect(model.plants.map((p) => p.name), ['Алоэ вера']);
    await model.load(); // retry / «Обновить» — фильтр сохранён
    expect(model.plants, hasLength(1));
    await model.load(search: ''); // сброс фильтра
    expect(model.plants, hasLength(mockPlants.length));
  });

  test('loadMore приклеивает следующую страницу, пока она полная', () async {
    final model = await modelWithPlants(17); // 8 + 17 = 25 растений
    await model.load();
    expect(model.plants, hasLength(PlantsModel.pageSize));
    expect(model.hasMore, isTrue); // полная страница → видимо, есть ещё

    await model.loadMore();
    expect(model.plants, hasLength(25));
    expect(model.plants.map((p) => p.id).toSet(), hasLength(25)); // без дублей
    expect(model.hasMore, isFalse); // неполная страница → конец
  });

  test('loadMore: guard — повторный вызов не тянет страницу дважды', () async {
    final model = await modelWithPlants(17);
    await model.load();
    await Future.wait([model.loadMore(), model.loadMore(), model.loadMore()]);
    expect(model.plants, hasLength(25));
  });
}
