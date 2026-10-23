import 'mock_data.dart';
import 'result.dart';
import 'watering_log.dart';
import 'watering_log_repository.dart';

// Журнал полива «в памяти»: задержка + переключаемый сбой, как у растений.
class MockWateringLogRepository implements WateringLogRepository {
  final List<WateringLog> _logs = List.of(mockWateringLogs); // копия seed-а
  int _nextId = 1000; // больше любого id из seed-а

  bool simulateError = false;

  static const _latency = Duration(milliseconds: 800);
  static const _errNetwork = 'Сервер не отвечает — повторите попытку';
  static const _errNotFound = 'Запись журнала не существует';

  Future<String?> _network() async {
    await Future.delayed(_latency);
    return simulateError ? _errNetwork : null;
  }

  @override
  Future<Result<List<WateringLog>>> fetchAll() async {
    final error = await _network();
    if (error != null) return Err(error);
    return Ok(List.of(_logs));
  }

  @override
  Future<Result<WateringLog>> create(WateringLog log) async {
    final error = await _network();
    if (error != null) return Err(error);
    final created = log.copyWith(id: _nextId++);
    _logs.add(created);
    return Ok(created);
  }

  @override
  Future<Result<void>> delete(int id) async {
    final error = await _network();
    if (error != null) return Err(error);
    final index = _logs.indexWhere((l) => l.id == id);
    if (index == -1) return const Err(_errNotFound);
    _logs.removeAt(index);
    return const Ok(null);
  }
}
