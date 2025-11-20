// lib/features/auth/data/auth_api.dart
import 'package:ayutthaya_camp/core/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthApi {
  final ApiClient _api;
  AuthApi(this._api);

  /// Llama a POST /api/users y espera { data: { customToken, uid, ... } }
  Future<String> register({
    required String email,
    required String password,
    String? displayName,
    Map<String, dynamic>? profile,
    String role = 'alumno',
  }) async {
     final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken(); // usa getIdToken(true) si quieres forzar refresh

    final payload = {
      'email': email,
      'password': password,
      if (displayName != null) 'displayName': displayName,
      'role': role,
      if (profile != null) 'profile': profile,
    };

    final headers = <String, String>{
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    // 2) LLAMAR AL BACKEND CON EL HEADER
    final json = await _api.post('/api/users', payload, headers: headers);
    final data = (json['data'] ?? {}) as Map<String, dynamic>;

    final token = data['customToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('No customToken returned by backend');
    }
    return token;
  }
}

 