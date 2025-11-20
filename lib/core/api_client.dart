// lib/core/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config.dart'; // Ajusta esta ruta si tu AppConfig está en otro path

class ApiClient {
  // base y client ahora se inyectan por constructor (con defaults)
  final String _base;
  final http.Client _client;

  /// Constructor:
  /// - [baseUrl]: si no lo pasas, usa AppConfig.apiBaseUrl
  /// - [client]: para tests puedes inyectar un MockClient
  ApiClient({String? baseUrl, http.Client? client})
      : _base = (baseUrl ?? AppConfig.apiBaseUrl),
        _client = client ?? http.Client();

  Uri _build(String path) {
    // evita paths relativos: usa Uri.parse(base).resolve()
    final base = Uri.parse('$_base/'); // base SIEMPRE con slash al final
    final clean = path.startsWith('/') ? path.substring(1) : path;
    final uri = base.resolve(clean);   // p.ej. resolve('api/escuelas')
    // ignore: avoid_print
    print('[ApiClient] -> $uri');
    return uri;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = _build(path);
    final res = await _client.get(uri, headers: headers);
    // ignore: avoid_print
    print('[ApiClient] ${res.statusCode} ${res.request?.url}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final uri = _build(path);
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: jsonEncode(body),
    );
    // ignore: avoid_print
    print('[ApiClient] ${res.statusCode} ${res.request?.url}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
}
