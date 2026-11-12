import 'dart:convert';

import 'package:http/http.dart' as http;

import 'network_errors.dart';
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

  // 401 = пропуск умер: token выбрасывается (C9), корень навигирует
  Future<String> sessionDied() async {
    await tokens.clear();
    onUnauthorized?.call();
    return 'Сессия истекла — войдите снова';
  }
}
