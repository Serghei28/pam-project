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
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _logs = [..._logs, value]; // с id, выданным хранилищем
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
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

  static List<WateringLog> _sorted(Iterable<WateringLog> logs) =>
      logs.toList()..sort((a, b) => b.date.compareTo(a.date));
}
