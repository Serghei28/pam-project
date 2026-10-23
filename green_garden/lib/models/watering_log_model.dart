import 'package:flutter/foundation.dart';

import '../data/result.dart';
import '../data/watering_log.dart';
import '../data/watering_log_repository.dart';

// Разделяемое состояние «Журнал полива»: его читают экран журнала,
// карточка растения (история поливов) и профиль (статистика).
class WateringLogModel extends ChangeNotifier {
  WateringLogModel(this._repository);

  final WateringLogRepository _repository;

  bool _loading = false;
  String? _error;
  List<WateringLog> _logs = const [];

  bool get isLoading => _loading;
  String? get error => _error;

  // Все записи, новые сверху
  List<WateringLog> get logs => List.unmodifiable(_sorted(_logs));

  // История поливов одного растения, новые сверху
  List<WateringLog> logsForPlant(int plantId) => List.unmodifiable(
        _sorted(_logs.where((l) => l.plantId == plantId)),
      );

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    switch (await _repository.fetchAll()) {
      case Ok(:final value):
        _logs = value;
      case Err(:final msg):
        _error = msg;
    }

    _loading = false;
    notifyListeners();
  }

  // Мутации: null — успех, строка — текст ошибки
  Future<String?> add(WateringLog draft) async {
    switch (await addEntry(draft)) {
      case Ok():
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  // То же, что add, но возвращает созданную запись (с id от хранилища).
  // Нужно сценариям из нескольких шагов (waterPlant), чтобы при сбое
  // следующего шага можно было откатить именно эту запись.
  Future<Result<WateringLog>> addEntry(WateringLog draft) async {
    final result = await _repository.create(draft);
    if (result case Ok(:final value)) {
      _logs = [..._logs, value]; // с id, выданным хранилищем
      notifyListeners();
    }
    return result;
  }

  Future<String?> remove(int id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _logs = _logs.where((l) => l.id != id).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  // Каскад: убрать всю историю поливов удалённого растения
  Future<String?> removeForPlant(int plantId) async {
    switch (await _repository.deleteByPlant(plantId)) {
      case Ok():
        _logs = _logs.where((l) => l.plantId != plantId).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  static List<WateringLog> _sorted(Iterable<WateringLog> logs) =>
      logs.toList()..sort((a, b) => b.date.compareTo(a.date));
}
