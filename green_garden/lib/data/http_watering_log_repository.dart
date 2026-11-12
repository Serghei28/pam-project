import 'dart:convert';

import 'api_client.dart';
import 'api_message.dart';
import 'network_errors.dart';
import 'result.dart';
import 'watering_log.dart';
import 'watering_log_repository.dart';

// http-реализация WateringLogRepository из L4 (интерфейс не изменился).
// Маршруты из каталога темы: GET/POST /watering-logs,
// DELETE /watering-logs/{id}.
class HttpWateringLogRepository implements WateringLogRepository {
  HttpWateringLogRepository(this._api);

  final ApiClient _api;

  // Весь журнал — модель строит из него историю каждого растения
  @override
  Future<Result<List<WateringLog>>> fetchAll() =>
      _api.fetchAllPages('/watering-logs', WateringLog.fromJson);

  @override
  Future<Result<WateringLog>> create(WateringLog log) =>
      withNetworkErrors(() async {
        final res = await _api.post(_api.uri('/watering-logs'), log.toJson());
        if (res.statusCode == 401) return Err(await _api.sessionDied());
        if (res.statusCode != 201) return Err(apiMessage(res));
        return Ok(
          WateringLog.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
        );
      });

  @override
  Future<Result<void>> delete(int id) => withNetworkErrors(() async {
    final res = await _api.delete(_api.uri('/watering-logs/$id'));
    if (res.statusCode == 401) return Err(await _api.sessionDied());
    if (res.statusCode != 204) return Err(apiMessage(res)); // хороший = 204
    return const Ok(null); // тело пустое
  });

  // Каскад делает сервер: DELETE /plants/{id} удаляет и журнал растения.
  // Запрашивать нечего — модель лишь убирает записи у себя.
  @override
  Future<Result<void>> deleteByPlant(int plantId) async => const Ok(null);
}
