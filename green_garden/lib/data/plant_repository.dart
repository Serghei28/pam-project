import 'plant.dart';
import 'result.dart';

// Контракт: ЧТО можно попросить у хранилища растений, а не КАК это сделано.
// Модели знают только этот интерфейс. Сегодня его реализует mock (L4),
// на L5 — http-вариант; экраны при этом не меняются.
//
// Метод                 -> на L5 станет
// fetchAll()            -> GET    /plants
// fetchById(id)         -> GET    /plants/{id}   (Err, если 404)
// create(plant)         -> POST   /plants        (id выдаёт сервер)
// update(plant)         -> PUT    /plants/{id}
// delete(id)            -> DELETE /plants/{id}   (204, пустое тело)
abstract class PlantRepository {
  Future<Result<List<Plant>>> fetchAll();

  Future<Result<Plant>> fetchById(int id);

  Future<Result<Plant>> create(Plant plant);

  Future<Result<Plant>> update(Plant plant);

  Future<Result<void>> delete(int id);
}
