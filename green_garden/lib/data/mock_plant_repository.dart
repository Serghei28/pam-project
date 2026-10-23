import 'mock_data.dart';
import 'plant.dart';
import 'plant_repository.dart';
import 'result.dart';

// Реализация PlantRepository «в памяти», с повадками сети:
// задержка ответа и переключаемый сбой. Единственный файл,
// который видит seed из mock_data.dart. На L5 его заменит http-вариант.
class MockPlantRepository implements PlantRepository {
  final List<Plant> _plants = List.of(mockPlants); // копия seed-а
  int _nextId = 1000; // больше любого id из seed-а

  // Сбой сети: включён → любой вызов возвращает Err
  bool simulateError = false;

  static const _latency = Duration(milliseconds: 800);
  static const _errNetwork = 'Сервер не отвечает — повторите попытку';
  static const _errNotFound = 'Растение не существует';

  // Общий пролог каждого метода: задержка + проверка сбоя.
  // Возвращает текст ошибки или null, если «сеть» ответила.
  Future<String?> _network() async {
    await Future.delayed(_latency); // сеть не отвечает мгновенно
    return simulateError ? _errNetwork : null;
  }

  @override
  Future<Result<List<Plant>>> fetchAll() async {
    final error = await _network();
    if (error != null) return Err(error);
    return Ok(List.of(_plants)); // копия — внутренний список не отдаём
  }

  @override
  Future<Result<Plant>> fetchById(int id) async {
    final error = await _network();
    if (error != null) return Err(error);
    final index = _plants.indexWhere((p) => p.id == id);
    if (index == -1) return const Err(_errNotFound); // «404» mock-а
    return Ok(_plants[index]);
  }

  @override
  Future<Result<Plant>> create(Plant plant) async {
    final error = await _network();
    if (error != null) return Err(error);
    final created = plant.copyWith(id: _nextId++); // id выдаёт ХРАНИЛИЩЕ
    _plants.add(created);
    return Ok(created);
  }

  @override
  Future<Result<Plant>> update(Plant plant) async {
    final error = await _network();
    if (error != null) return Err(error);
    final index = _plants.indexWhere((p) => p.id == plant.id);
    if (index == -1) return const Err(_errNotFound);
    _plants[index] = plant; // заменяем по id
    return Ok(plant);
  }

  @override
  Future<Result<void>> delete(int id) async {
    final error = await _network();
    if (error != null) return Err(error);
    final index = _plants.indexWhere((p) => p.id == id);
    if (index == -1) return const Err(_errNotFound);
    _plants.removeAt(index);
    return const Ok(null); // «удалил, отдать нечего» — как 204
  }
}
