import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'result.dart';

// Таймаут каждого запроса к backend-у: без .timeout запрос к «молчащему»
// серверу может висеть бесконечно.
const apiTimeout = Duration(seconds: 8);

// Слои отказа C8, которые БРОСАЮТ исключения, — в одном месте:
// 1) упала дорога: нет сети / сервер не отвечает;
// 3) тело-сюрприз: не JSON (FormatException) или не та форма (TypeError).
// Слой 2 (дурная весть сервера: 400/404/409...) не бросает — его читают
// по statusCode в самом запросе и переводят через apiMessage.
// Все ветки стекаются в Err(msg), UI видит только Result.
Future<Result<T>> withNetworkErrors<T>(
  Future<Result<T>> Function() request,
) async {
  try {
    return await request();
  } on SocketException {
    return const Err('Нет сети — повторите попытку');
  } on http.ClientException {
    // Flutter web: отказ сети приходит как ClientException, не SocketException
    return const Err('Нет сети — повторите попытку');
  } on TimeoutException {
    return const Err('Сервер не отвечает');
  } on FormatException {
    return const Err('Ответ не тот, что обещан');
  } on TypeError {
    return const Err('Ответ не тот, что обещан');
  }
}
