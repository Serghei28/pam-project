import 'result.dart';
import 'watering_log.dart';

// Контракт хранилища журнала полива.
// Методы совпадают с endpoint-ами backend-а для L5:
// fetchAll()   -> GET    /watering-logs
// create(log)  -> POST   /watering-logs        (id выдаёт сервер)
// delete(id)   -> DELETE /watering-logs/{id}   (204, пустое тело)
// deleteByPlant(id)    -> DELETE /watering-logs?plantId={id}
//                         (или каскад на сервере при DELETE /plants/{id})
// Изменения записи (PUT) в контракте backend-а нет, поэтому нет и update.
abstract class WateringLogRepository {
  Future<Result<List<WateringLog>>> fetchAll();

  Future<Result<WateringLog>> create(WateringLog log);

  Future<Result<void>> delete(int id);

  // Удалить всю историю поливов растения (каскад при удалении растения).
  // Если записей нет — это тоже успех.
  Future<Result<void>> deleteByPlant(int plantId);
}
