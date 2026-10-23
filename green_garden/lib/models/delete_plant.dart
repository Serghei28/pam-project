import 'plants_model.dart';
import 'reminder_model.dart';
import 'watering_log_model.dart';

// Удаление растения затрагивает три вида данных: само растение,
// его напоминания и его историю поливов (каскад).
// Функция чистая (без BuildContext) — экраны передают в неё модели.
// Возвращает null при успехе или текст ошибки.
Future<String?> deletePlant({
  required PlantsModel plants,
  required ReminderModel reminders,
  required WateringLogModel logs,
  required int plantId,
}) async {
  // 1) Сначала само растение: если не удалилось — остальное не трогаем
  final plantError = await plants.remove(plantId);
  if (plantError != null) return plantError;

  // 2) Затем связанные данные
  final reminderError = await reminders.removeForPlant(plantId);
  final logError = await logs.removeForPlant(plantId);

  final error = reminderError ?? logError;
  if (error != null) {
    return 'Растение удалено, но связанные данные — нет: $error';
  }
  return null;
}
