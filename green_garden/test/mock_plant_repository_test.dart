import 'package:flutter_test/flutter_test.dart';
import 'package:green_garden/data/mock_data.dart';
import 'package:green_garden/data/mock_network.dart';
import 'package:green_garden/data/result.dart';

import 'helpers.dart';

void main() {
  test('fetchAll возвращает seed-данные', () async {
    final result = await fastPlantRepo().fetchAll();
    expect(result, isA<Ok>());
    expect((result as Ok).value, hasLength(mockPlants.length));
  });

  test('create выдаёт новый id из хранилища', () async {
    final repo = fastPlantRepo();
    final first = await repo.create(mockPlants.first.copyWith(id: 0));
    final second = await repo.create(mockPlants.first.copyWith(id: 0));
    expect((first as Ok).value.id, mockFirstNewId);
    expect((second as Ok).value.id, mockFirstNewId + 1);
  });

  test('при simulateError любой вызов возвращает Err', () async {
    final repo = fastPlantRepo()..simulateError = true;
    final result = await repo.fetchAll();
    expect(result, isA<Err>());
    expect((result as Err).msg, mockNetworkError);
  });

  test('update и delete несуществующего id — Err («404»)', () async {
    final repo = fastPlantRepo();
    expect(await repo.delete(999), isA<Err>());
    expect(await repo.update(mockPlants.first.copyWith(id: 999)), isA<Err>());
  });
}
