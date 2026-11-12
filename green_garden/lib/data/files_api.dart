import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_client.dart';
import 'api_message.dart';
import 'network_errors.dart';
import 'result.dart';

// Загрузка файлов шаблона: POST /files (multipart, поле file, до 5 МБ)
// → 201 {id, url, name, size, mimeType}; GET /files/{id} отдаёт байты
// без token-а — поэтому Image.network работает по простому адресу.
class FilesApi {
  FilesApi(this._api);

  final ApiClient _api;

  // Лимит шаблона: больше — сервер ответит 400
  static const maxBytes = 5 * 1024 * 1024;

  // url из ответа сервера (/files/12) → полный адрес для Image.network
  String imageUrl(String url) => '${_api.baseUrl}$url';

  // Возвращает url загруженного файла (его и хранит сущность: photoUrl)
  Future<Result<String>> upload(
    Uint8List bytes,
    String filename, {
    String? mimeType,
  }) => withNetworkErrors(() async {
    if (bytes.length > maxBytes) {
      return const Err('Файл больше 5 МБ — выберите другое фото');
    }
    final type = mimeType ?? _mimeFromName(filename);
    // У multipart-запроса свой класс; Content-Type с boundary он ставит сам
    final request = http.MultipartRequest('POST', _api.uri('/files'))
      ..headers['Authorization'] = 'Bearer ${await _api.tokens.read() ?? ''}'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: type == null ? null : MediaType.parse(type),
        ),
      );
    final res = await http.Response.fromStream(
      await request.send().timeout(apiTimeout),
    ).timeout(apiTimeout);

    if (res.statusCode == 401) return Err(await _api.sessionDied());
    if (res.statusCode != 201) return Err(apiMessage(res)); // 400 — > 5 МБ
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Ok(data['url'] as String);
  });

  // Тип по расширению — если платформа не сообщила mimeType
  static String? _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => null,
    };
  }
}
