import 'package:green_garden/data/plant.dart';
import 'package:green_garden/data/plant_repository.dart';
import 'package:green_garden/data/result.dart';

import 'mock_data.dart';
import 'mock_network.dart';

// Реализация PlantRepository «в памяти», с повадками сети:
// задержка ответа и переключаемый сбой. Единственный файл,
// который видит seed из mock_data.dart. В приложении с L5 — http-вариант,
// здесь — тестовый двойник.
class MockPlantRepository with MockNetwork implements PlantRepository {
  final List<Plant> _plants = List.of(mockPlants); // копия seed-а
  int _nextId = mockFirstNewId; // больше любого id из seed-а

  static const _errNotFound = 'Растение не существует';

  @override
  Future<Result<List<Plant>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final error = await simulateNetwork();
    if (error != null) return Err(error);
    // Как сервер: поиск по названию и виду, затем ломоть страницы
    final query = search?.toLowerCase() ?? '';
    final found = _plants.where(
      (p) =>
          p.name.toLowerCase().contains(query) ||
          p.species.toLowerCase().contains(query),
    );
    // копия — внутренний список не отдаём
    return Ok(found.skip((page - 1) * limit).take(limit).toList());
  }

  @override
  Future<Result<Plant>> fetchById(int id) async {
    final error = await simulateNetwork();
    if (error != null) return Err(error);
    final index = _plants.indexWhere((p) => p.id == id);
    if (index == -1) return const Err(_errNotFound); // «404» mock-а
    return Ok(_plants[index]);
  }

  @override
  Future<Result<Plant>> create(Plant plant) async {
    final error = await simulateNetwork();
    if (error != null) return Err(error);
    final created = plant.copyWith(id: _nextId++); // id выдаёт ХРАНИЛИЩЕ
    _plants.add(created);
    return Ok(created);
  }

  @override
  Future<Result<Plant>> update(Plant plant) async {
    final error = await simulateNetwork();
    if (error != null) return Err(error);
    final index = _plants.indexWhere((p) => p.id == plant.id);
    if (index == -1) return const Err(_errNotFound);
    _plants[index] = plant; // заменяем по id
    return Ok(plant);
  }

  @override
  Future<Result<void>> delete(int id) async {
    final error = await simulateNetwork();
    if (error != null) return Err(error);
    final index = _plants.indexWhere((p) => p.id == id);
    if (index == -1) return const Err(_errNotFound);
    _plants.removeAt(index);
    return const Ok(null); // «удалил, отдать нечего» — как 204
  }
}
