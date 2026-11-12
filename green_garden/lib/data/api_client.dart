import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'network_errors.dart';
import 'result.dart';
import 'token_store.dart';

// Общее для всех http-репозиториев: адрес сервера, пропуск (Bearer),
// таймаут на каждом запросе и реакция на 401. Сами репозитории
// остаются про своё: маршрут, хороший статус и fromJson.
class ApiClient {
  ApiClient(this.baseUrl, this.tokens, {this.onUnauthorized});

  final String baseUrl;
  final TokenStore tokens;

  // Решает корень композиции: назад на login. Репозиторий router не знает.
  final void Function()? onUnauthorized;

  Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await tokens.read() ?? ''}', // C8: Bearer
  };

  Future<http.Response> get(Uri url) async =>
      http.get(url, headers: await _headers()).timeout(apiTimeout);

  Future<http.Response> post(Uri url, Object body) async => http
      .post(url, headers: await _headers(), body: jsonEncode(body))
      .timeout(apiTimeout);

  Future<http.Response> put(Uri url, Object body) async => http
      .put(url, headers: await _headers(), body: jsonEncode(body))
      .timeout(apiTimeout);

  Future<http.Response> delete(Uri url) async =>
      http.delete(url, headers: await _headers()).timeout(apiTimeout);

  // Максимальный limit, который принимает сервер
  static const maxPageSize = 100;

  // GET всех страниц пагинированного конверта {items, page, limit, total}.
  // Для данных, которые модель держит целиком (журнал, напоминания):
  // страницы просятся, пока не собрано total элементов.
  Future<Result<List<T>>> fetchAllPages<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson,
  ) => withNetworkErrors(() async {
    final items = <T>[];
    for (var page = 1; ; page++) {
      final res = await get(
        uri(path, {'page': '$page', 'limit': '$maxPageSize'}),
      );
      if (res.statusCode == 401) return Err(await sessionDied());
      if (res.statusCode != 200) return Err(apiMessage(res)); // слой 2
      final data = jsonDecode(res.body) as Map<String, dynamic>; // конверт
      final chunk = data['items'] as List;
      items.addAll(chunk.map((e) => fromJson(e as Map<String, dynamic>)));
      // пустая страница — страховка от бесконечного цикла
      if (chunk.isEmpty || items.length >= (data['total'] as int)) {
        return Ok(items);
      }
    }
  });

  // 401 = пропуск умер: token выбрасывается (C9), корень навигирует
  Future<String> sessionDied() async {
    await tokens.clear();
    onUnauthorized?.call();
    return 'Сессия истекла — войдите снова';
  }
}
