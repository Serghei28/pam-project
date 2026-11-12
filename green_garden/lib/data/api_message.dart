import 'dart:convert';

import 'package:http/http.dart' as http;

// Конверт ошибки контракта: {"error": {"code": "...", "message": "..."}}.
// code стабилен и принадлежит программе; английский message на экран
// не попадает — русский текст решается здесь, в одном месте.
String apiMessage(http.Response res) {
  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final error = body['error'] as Map<String, dynamic>;
    final code = error['code'] as String;
    return switch (code) {
      'VALIDATION_ERROR' => 'Отправленные данные недействительны',
      'UNAUTHORIZED' => 'Неверный email или пароль',
      'EMAIL_TAKEN' => 'Аккаунт с этим email уже существует',
      'NOT_FOUND' => 'Запись не существует',
      _ => 'Ошибка сервера ($code)',
    };
  } on FormatException {
    // тело вне контракта: не JSON (например, HTML-страница 500)
    return 'Ошибка сервера (${res.statusCode})';
  } on TypeError {
    // JSON, но не конверт ошибки
    return 'Ошибка сервера (${res.statusCode})';
  }
}
