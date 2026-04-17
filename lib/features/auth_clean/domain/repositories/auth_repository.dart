import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Auth Repository Interface (Domain Layer)
/// Defines contracts for authentication operations
/// Implementation details are in the Data layer
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Get current user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Send email verification
  Future<Either<Failure, void>> sendEmailVerification();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Stream of auth state changes
  Stream<UserEntity?> get authStateChanges;

  /// Check if email is verified
  Future<Either<Failure, bool>> isEmailVerified();

  /// Reload user (refresh email verified status)
  Future<Either<Failure, void>> reloadUser();

  /// Update user profile
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Delete account
  Future<Either<Failure, void>> deleteAccount();
}
