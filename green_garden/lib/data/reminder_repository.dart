import 'reminder.dart';
import 'result.dart';

// Контракт хранилища напоминаний. На L5:
// fetchAll()          -> GET    /reminders
// fetchById(id)       -> GET    /reminders/{id}   (Err, если 404)
// create(reminder)    -> POST   /reminders        (id выдаёт сервер)
// update(reminder)    -> PUT    /reminders/{id}   (например, isDone)
// delete(id)          -> DELETE /reminders/{id}   (204, пустое тело)
// deleteByPlant(id)   -> DELETE /reminders?plantId={id}
//                        (или каскад на сервере при DELETE /plants/{id})
abstract class ReminderRepository {
  Future<Result<List<Reminder>>> fetchAll();

  Future<Result<Reminder>> fetchById(int id);

  Future<Result<Reminder>> create(Reminder reminder);

  Future<Result<Reminder>> update(Reminder reminder);

  Future<Result<void>> delete(int id);

  // Удалить все напоминания растения (каскад при удалении растения).
  // Если напоминаний нет — это тоже успех.
  Future<Result<void>> deleteByPlant(int plantId);
}
