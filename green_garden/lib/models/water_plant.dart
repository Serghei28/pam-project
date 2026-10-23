import '../data/result.dart';
import '../data/watering_log.dart';
import 'plants_model.dart';
import 'watering_log_model.dart';

// Полив затрагивает два вида данных:
// новая запись в журнале + новая дата последнего полива у растения.
// Функция чистая (без BuildContext) — экраны передают в неё модели.
// Возвращает null при успехе или текст ошибки.
Future<String?> waterPlant({
  required PlantsModel plants,
  required WateringLogModel logs,
  required int plantId,
  String note = '',
}) async {
  final now = DateTime.now();

  // 1) Запись в журнал (id: 0 — временный, настоящий выдаст хранилище)
  final WateringLog created;
  switch (await logs.addEntry(
    WateringLog(id: 0, plantId: plantId, date: now, note: note),
  )) {
    case Ok(:final value):
      created = value;
    case Err(:final msg):
      return msg;
  }

  // 2) Новая дата полива у растения
  final plantError = await plants.markWatered(plantId, at: now);
  if (plantError != null) {
    // Откат шага 1: журнал не должен говорить «полито»,
    // если растение так и не обновилось.
    await logs.remove(created.id);
    return plantError;
  }
  return null;
}
