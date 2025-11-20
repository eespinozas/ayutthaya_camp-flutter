import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config.dart';

class Escuela {
  final String id;
  final String nombre;

  const Escuela({required this.id, required this.nombre});

  factory Escuela.fromMap(Map<String, dynamic> map) {
    return Escuela(
      id: (map['id'] ?? map['_id'] ?? map['uuid'] ?? '').toString(),
      nombre: (map['nombre'] ?? map['name'] ?? '').toString(),
    );
  }
}

class EscuelasRepositoryHttp {
  final http.Client _client;
  EscuelasRepositoryHttp({http.Client? client}) : _client = client ?? http.Client();

  /// GET {API_BASE_URL}/escuelas
  /// Espera una lista JSON como:
  /// [{ "id":"abc123", "nombre":"Ayutthaya Camp Centro" }, ...]
  Future<List<Escuela>> fetchEscuelas() async {
    
    print(" base url "+AppConfig.apiBaseUrl);
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/escuelas');
    final res = await _client.get(uri, headers: {
      'Accept': 'application/json',
      // Agrega Authorization si tu backend lo requiere:
      // 'Authorization': 'Bearer $token',
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error ${res.statusCode} obteniendo escuelas');
    }

    final body = json.decode(res.body);
    if (body is List) {
      return body.map((e) => Escuela.fromMap(e as Map<String, dynamic>)).toList();
    } else if (body is Map && body['data'] is List) {
      // Por si tu backend responde { data: [...] }
      final list = (body['data'] as List).cast<dynamic>();
      return list.map((e) => Escuela.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Formato de respuesta inválido');
  }
}
