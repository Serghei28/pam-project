import 'dart:convert';

import 'api_client.dart';
import 'api_message.dart';
import 'network_errors.dart';
import 'plant.dart';
import 'plant_repository.dart';
import 'result.dart';

// Вторая реализация интерфейса PlantRepository из L4 — на http.
// Интерфейс не изменился: модели и экраны не узнают о смене источника.
// Вердикты читаются сверху вниз — три слоя C8:
// упавшая дорога / тело-сюрприз → withNetworkErrors (исключения);
// дурная весть сервера → if по statusCode + apiMessage (не бросает).
class HttpPlantRepository implements PlantRepository {
  HttpPlantRepository(this._api);

  final ApiClient _api;

  static Plant _plant(String body) =>
      Plant.fromJson(jsonDecode(body) as Map<String, dynamic>);

  @override
  Future<Result<List<Plant>>> fetchAll() => withNetworkErrors(() async {
    final res = await _api.get(_api.uri('/plants')); // GET /plants
    if (res.statusCode == 401) return Err(await _api.sessionDied());
    if (res.statusCode != 200) return Err(apiMessage(res)); // слой 2
    final data = jsonDecode(res.body) as Map<String, dynamic>; // конверт!
    return Ok(
      (data['items'] as List)
          .map((e) => Plant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  });

  @override
  Future<Result<Plant>> fetchById(int id) => withNetworkErrors(() async {
    final res = await _api.get(_api.uri('/plants/$id'));
    if (res.statusCode == 401) return Err(await _api.sessionDied());
    if (res.statusCode != 200) return Err(apiMessage(res)); // 404 → Err
    return Ok(_plant(res.body));
  });

  @override
  Future<Result<Plant>> create(Plant plant) => withNetworkErrors(() async {
    final res = await _api.post(_api.uri('/plants'), plant.toJson());
    if (res.statusCode == 401) return Err(await _api.sessionDied());
    if (res.statusCode != 201) return Err(apiMessage(res)); // хороший = 201
    return Ok(_plant(res.body)); // id выдал сервер
  });

  @override
  Future<Result<Plant>> update(Plant plant) => withNetworkErrors(() async {
    final res = await _api.put(_api.uri('/plants/${plant.id}'), plant.toJson());
    if (res.statusCode == 401) return Err(await _api.sessionDied());
    if (res.statusCode != 200) return Err(apiMessage(res));
    return Ok(_plant(res.body));
  });

  @override
  Future<Result<void>> delete(int id) => withNetworkErrors(() async {
    final res = await _api.delete(_api.uri('/plants/$id'));
    if (res.statusCode == 401) return Err(await _api.sessionDied());
    if (res.statusCode != 204) return Err(apiMessage(res)); // хороший = 204
    return const Ok(null); // тело пустое — jsonDecode на нём нельзя (C8)
  });
}
