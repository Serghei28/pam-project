import 'mock_data.dart';
import 'mock_network.dart';
import 'result.dart';
import 'watering_log.dart';
import 'watering_log_repository.dart';

// Журнал полива «в памяти»: задержка + переключаемый сбой, как у растений.
class MockWateringLogRepository with MockNetwork implements WateringLogRepository {
  final List<WateringLog> _logs = List.of(mockWateringLogs); // копия seed-а
  int _nextId = mockFirstNewId; // больше любого id из seed-а

  static const _errNotFound = 'Запись журнала не существует';

  @override
  Future<Result<List<WateringLog>>> fetchAll() async {
    final error = await simulateNetwork();
    if (error != null) return Err(error);
    return Ok(List.of(_logs));
  }

  @override
  Future<Result<WateringLog>> create(WateringLog log) async {
    final error = await simulateNetwork();
    if (error != null) return Err(error);
    final created = log.copyWith(id: _nextId++);
    _logs.add(created);
    return Ok(created);
  }

  @override
  Future<Result<void>> delete(int id) async {
    final error = await simulateNetwork();
    if (error != null) return Err(error);
    final index = _logs.indexWhere((l) => l.id == id);
    if (index == -1) return const Err(_errNotFound);
    _logs.removeAt(index);
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteByPlant(int plantId) async {
    final error = await simulateNetwork();
    if (error != null) return Err(error);
    _logs.removeWhere((l) => l.plantId == plantId);
    return const Ok(null);
  }
}
