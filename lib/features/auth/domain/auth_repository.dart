// lib/features/auth/domain/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_api.dart';

class AuthRepository {
  final AuthApi api;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthRepository(this.api);

  Future<UserCredential> registerAndSignIn({
    required String email,
    required String password,
    String? displayName,
    Map<String, dynamic>? profile,
  }) async {
    // 1) Crea en backend y obtiene custom token
    final customToken = await api.register(
      email: email,
      password: password,
      displayName: displayName,
      profile: profile,
    );

    // 2) Inicia sesión con custom token
    final cred = await _auth.signInWithCustomToken(customToken);

    // 3) (opcional) Actualiza displayName local si hace falta
    if (displayName != null && displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
    }
    return cred;
  }
}
