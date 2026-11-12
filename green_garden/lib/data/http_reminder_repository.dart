import 'dart:convert';

import 'api_client.dart';
import 'api_message.dart';
import 'network_errors.dart';
import 'reminder.dart';
import 'reminder_repository.dart';
import 'result.dart';

// http-реализация ReminderRepository из L4 (интерфейс не изменился).
// Маршруты: GET/POST /reminders, GET/PUT/DELETE /reminders/{id};
// PUT — в том числе отметка «выполнено».
class HttpReminderRepository implements ReminderRepository {
  HttpReminderRepository(this._api);

  final ApiClient _api;

  static Reminder _reminder(String body) =>
      Reminder.fromJson(jsonDecode(body) as Map<String, dynamic>);

  // Все напоминания — из них считаются бейджи и статистика
  @override
  Future<Result<List<Reminder>>> fetchAll() =>
      _api.fetchAllPages('/reminders', Reminder.fromJson);

  @override
  Future<Result<Reminder>> fetchById(int id) => withNetworkErrors(() async {
    final res = await _api.get(_api.uri('/reminders/$id'));
    if (res.statusCode == 401) return Err(await _api.sessionDied());
    if (res.statusCode != 200) return Err(apiMessage(res)); // 404 → Err
    return Ok(_reminder(res.body));
  });

  @override
  Future<Result<Reminder>> create(Reminder reminder) =>
      withNetworkErrors(() async {
        final res = await _api.post(_api.uri('/reminders'), reminder.toJson());
        if (res.statusCode == 401) return Err(await _api.sessionDied());
        if (res.statusCode != 201) return Err(apiMessage(res));
        return Ok(_reminder(res.body)); // id выдал сервер
      });

  @override
  Future<Result<Reminder>> update(Reminder reminder) =>
      withNetworkErrors(() async {
        final res = await _api.put(
          _api.uri('/reminders/${reminder.id}'),
          reminder.toJson(),
        );
        if (res.statusCode == 401) return Err(await _api.sessionDied());
        if (res.statusCode != 200) return Err(apiMessage(res));
        return Ok(_reminder(res.body));
      });

  @override
  Future<Result<void>> delete(int id) => withNetworkErrors(() async {
    final res = await _api.delete(_api.uri('/reminders/$id'));
    if (res.statusCode == 401) return Err(await _api.sessionDied());
    if (res.statusCode != 204) return Err(apiMessage(res)); // хороший = 204
    return const Ok(null); // тело пустое
  });

  // Каскад делает сервер: DELETE /plants/{id} удаляет и напоминания.
  @override
  Future<Result<void>> deleteByPlant(int plantId) async => const Ok(null);
}
