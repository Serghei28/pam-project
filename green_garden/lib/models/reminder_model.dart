import 'package:flutter/foundation.dart';

import '../data/reminder.dart';
import '../data/reminder_repository.dart';
import '../data/result.dart';

// Разделяемое состояние «Напоминания»: его читают экран напоминаний,
// карточка растения и профиль (статистика).
class ReminderModel extends ChangeNotifier {
  ReminderModel(this._repository);

  final ReminderRepository _repository;

  bool _loading = false;
  String? _error;
  List<Reminder> _reminders = const [];

  bool get isLoading => _loading;
  String? get error => _error;

  // Все напоминания, ближайший срок сверху
  List<Reminder> get reminders => List.unmodifiable(_sorted(_reminders));

  List<Reminder> get pending =>
      List.unmodifiable(_sorted(_reminders.where((r) => !r.isDone)));

  List<Reminder> get done =>
      List.unmodifiable(_sorted(_reminders.where((r) => r.isDone)));

  // Сколько напоминаний ещё не выполнено
  int get pendingCount => _reminders.where((r) => !r.isDone).length;

  // Невыполненные напоминания одного растения
  List<Reminder> pendingForPlant(int plantId) => List.unmodifiable(
        _sorted(_reminders.where((r) => r.plantId == plantId && !r.isDone)),
      );

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    switch (await _repository.fetchAll()) {
      case Ok(:final value):
        _reminders = value;
      case Err(:final msg):
        _error = msg;
    }

    _loading = false;
    notifyListeners();
  }

  // Мутации: null — успех, строка — текст ошибки

  Future<String?> add(Reminder draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _reminders = [..._reminders, value];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> update(Reminder reminder) async {
    switch (await _repository.update(reminder)) {
      case Ok(:final value):
        _reminders = [
          for (final r in _reminders) r.id == value.id ? value : r,
        ];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> remove(int id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _reminders = _reminders.where((r) => r.id != id).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  // Каскад: убрать все напоминания удалённого растения
  Future<String?> removeForPlant(int plantId) async {
    switch (await _repository.deleteByPlant(plantId)) {
      case Ok():
        _reminders = _reminders.where((r) => r.plantId != plantId).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  // Отметить выполненным / вернуть в невыполненные
  Future<String?> toggleDone(int id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return 'Напоминание не существует';
    final reminder = _reminders[index];
    return update(reminder.copyWith(isDone: !reminder.isDone));
  }

  static List<Reminder> _sorted(Iterable<Reminder> reminders) =>
      reminders.toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
}
