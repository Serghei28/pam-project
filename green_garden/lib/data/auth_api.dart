import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'network_errors.dart';
import 'result.dart';
import 'token_store.dart';

// register/login по контракту шаблона; token уходит в TokenStore.
class AuthApi {
  AuthApi(this.baseUrl, this.tokens);

  final String baseUrl;
  final TokenStore tokens;

  Future<Result<void>> register(String email, String password, String name) =>
      _post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });

  Future<Result<void>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<void> logout() => tokens.clear();

  // register и login разнятся лишь путём и телом
  Future<Result<void>> _post(String path, Map<String, Object?> body) =>
      withNetworkErrors(() async {
        final res = await http
            .post(
              Uri.parse('$baseUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(apiTimeout);
        if (res.statusCode != 200 && res.statusCode != 201) {
          return Err(apiMessage(res)); // слой 2: 400 / 401 / 409, из конверта
        }
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await tokens.save(data['token'] as String); // C9: setString
        return const Ok(null);
      });
}
