import 'package:flutter/foundation.dart';

import '../data/plant.dart';

// Разделяемое состояние «Мои растения»: чистый Dart, без widget-ов.
// Его читают список, карточка и бейдж на вкладке «Растения».
class PlantsModel extends ChangeNotifier {
  // Временно (до шага 7) стартовый список приходит через конструктор,
  // потом его заменит repository.
  PlantsModel(List<Plant> initialPlants) : _plants = List.of(initialPlants);

  final List<Plant> _plants;

  // Наружу — только read-only копия: изменить список можно лишь
  // через методы модели, которые вызывают notifyListeners().
  List<Plant> get plants => List.unmodifiable(_plants);

  // Сколько растений пора полить — для бейджа на вкладке
  int get dueCount => _plants.where((p) => p.needsWatering).length;

  // Поиск по id в текущем списке; null — если такого растения нет
  Plant? byId(int id) => _plants.where((p) => p.id == id).firstOrNull;

  // Отметить полив: дата последнего полива = сейчас
  void markWatered(int id) {
    final index = _plants.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _plants[index] = _plants[index].copyWith(lastWateredAt: DateTime.now());
    notifyListeners(); // весть уходит ко всем подписанным экранам
  }
}
