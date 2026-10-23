import '../data/watering_log.dart';
import 'plants_model.dart';
import 'watering_log_model.dart';

// Удаление записи журнала. Если удалили САМЫЙ ПОСЛЕДНИЙ полив растения,
// дата последнего полива у растения пересчитывается по оставшимся записям —
// иначе статус «полито» и срок следующего полива были бы неверными.
// Функция чистая (без BuildContext). Возвращает null или текст ошибки.
Future<String?> deleteWateringLog({
  required PlantsModel plants,
  required WateringLogModel logs,
  required WateringLog log,
}) async {
  // logsForPlant отсортирован: новые сверху
  final wasLatest = logs.logsForPlant(log.plantId).firstOrNull?.id == log.id;

  final error = await logs.remove(log.id);
  if (error != null) return error;
  if (!wasLatest) return null; // удалили старую запись — дата не меняется

  final plant = plants.byId(log.plantId);
  if (plant == null) return null; // растения уже нет

  final latest = logs.logsForPlant(log.plantId).firstOrNull;
  // Других записей нет — оставляем дату как есть: сведений о поливе больше нет
  if (latest == null) return null;

  return plants.update(plant.copyWith(lastWateredAt: latest.date));
}
