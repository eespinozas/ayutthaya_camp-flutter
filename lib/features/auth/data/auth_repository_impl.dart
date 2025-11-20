// lib/features/auth/data/auth_repository_impl.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_api.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi api;
  final FirebaseAuth _auth;

  AuthRepositoryImpl({required this.api, FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<UserCredential> registerAndSignIn({
    required String email,
    required String password,
    String? displayName,
    Map<String, dynamic>? profile,
  }) async {
    final customToken = await api.register(
      email: email,
      password: password,
      displayName: displayName,
      profile: profile,
    );
    final cred = await _auth.signInWithCustomToken(customToken);
    if (displayName != null && displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
    }
    return cred;
  }
}
