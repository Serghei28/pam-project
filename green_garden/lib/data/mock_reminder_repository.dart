import 'mock_data.dart';
import 'reminder.dart';
import 'reminder_repository.dart';
import 'result.dart';

// Напоминания «в памяти»: задержка + переключаемый сбой.
class MockReminderRepository implements ReminderRepository {
  final List<Reminder> _reminders = List.of(mockReminders); // копия seed-а
  int _nextId = 1000; // больше любого id из seed-а

  bool simulateError = false;

  static const _latency = Duration(milliseconds: 800);
  static const _errNetwork = 'Сервер не отвечает — повторите попытку';
  static const _errNotFound = 'Напоминание не существует';

  Future<String?> _network() async {
    await Future.delayed(_latency);
    return simulateError ? _errNetwork : null;
  }

  @override
  Future<Result<List<Reminder>>> fetchAll() async {
    final error = await _network();
    if (error != null) return Err(error);
    return Ok(List.of(_reminders));
  }

  @override
  Future<Result<Reminder>> fetchById(int id) async {
    final error = await _network();
    if (error != null) return Err(error);
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return const Err(_errNotFound);
    return Ok(_reminders[index]);
  }

  @override
  Future<Result<Reminder>> create(Reminder reminder) async {
    final error = await _network();
    if (error != null) return Err(error);
    final created = reminder.copyWith(id: _nextId++);
    _reminders.add(created);
    return Ok(created);
  }

  @override
  Future<Result<Reminder>> update(Reminder reminder) async {
    final error = await _network();
    if (error != null) return Err(error);
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return const Err(_errNotFound);
    _reminders[index] = reminder;
    return Ok(reminder);
  }

  @override
  Future<Result<void>> delete(int id) async {
    final error = await _network();
    if (error != null) return Err(error);
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return const Err(_errNotFound);
    _reminders.removeAt(index);
    return const Ok(null);
  }
}
