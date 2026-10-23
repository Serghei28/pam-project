import 'package:flutter/foundation.dart';

import '../data/plant.dart';
import '../data/plant_repository.dart';
import '../data/result.dart';

// Разделяемое состояние «Мои растения»: чистый Dart, без widget-ов.
// Его читают список, карточка и бейдж на вкладке «Растения».
class PlantsModel extends ChangeNotifier {
  // Простой DI: хранилище приходит через конструктор.
  PlantsModel(this._repository);

  // Тип поля — ИНТЕРФЕЙС, а не mock: модель не знает, откуда данные.
  final PlantRepository _repository;

  // Триада состояний с C8: грузится / ошибка / данные
  bool _loading = false;
  String? _error;
  List<Plant> _plants = const [];

  bool get isLoading => _loading;
  String? get error => _error;

  // Наружу — только read-only копия: изменить список можно лишь
  // через методы модели, которые вызывают notifyListeners().
  List<Plant> get plants => List.unmodifiable(_plants);

  // Сколько растений пора полить — для бейджа на вкладке
  int get dueCount => _plants.where((p) => p.needsWatering).length;

  // Поиск в загруженном списке; null — если такого растения нет
  Plant? byId(int id) => _plants.where((p) => p.id == id).firstOrNull;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners(); // экраны входят в состояние «грузится»

    switch (await _repository.fetchAll()) {
      case Ok(:final value):
        _plants = value;
      case Err(:final msg):
        _error = msg;
    }

    _loading = false;
    notifyListeners(); // …и выходят: с данными или с ошибкой
  }

  // Мутации возвращают null при успехе или текст ошибки (как validator).

  Future<String?> add(Plant draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _plants = [..._plants, value]; // с id, выданным хранилищем
        notifyListeners(); // список, бейдж, статистика узнают сразу
        return null;
      case Err(:final msg):
        return msg; // состояние не трогаем — экран решит, что показать
    }
  }

  Future<String?> update(Plant plant) async {
    switch (await _repository.update(plant)) {
      case Ok(:final value):
        _plants = [
          for (final p in _plants) p.id == value.id ? value : p,
        ];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg; // состояние не трогаем — экран решит, что показать
    }
  }

  Future<String?> remove(int id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _plants = _plants.where((p) => p.id != id).toList();
        notifyListeners(); // растение исчезнет со всех экранов
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  // Отметить полив = обновить дату последнего полива через хранилище
  Future<String?> markWatered(int id, {DateTime? at}) async {
    final plant = byId(id);
    if (plant == null) return 'Растение не существует';
    return update(plant.copyWith(lastWateredAt: at ?? DateTime.now()));
  }
}
