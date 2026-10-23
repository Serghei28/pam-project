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

  final logError = await logs.add(
    WateringLog(id: 0, plantId: plantId, date: now, note: note),
  ); // id: 0 — временный, настоящий выдаст хранилище
  if (logError != null) return logError;

  return plants.markWatered(plantId, at: now);
}
