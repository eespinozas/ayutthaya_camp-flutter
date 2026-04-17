import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Sign In with Email Use Case
/// Single Responsibility: Handle email/password sign in logic
class SignInWithEmailUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) async {
    // Business logic can go here (e.g., validation)
    if (!_isEmailValid(params.email)) {
      return Left(ValidationFailure('Email inválido'));
    }

    if (!_isPasswordValid(params.password)) {
      return Left(ValidationFailure('Contraseña debe tener al menos 6 caracteres'));
    }

    return await repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    return password.length >= 6;
  }
}

/// Parameters for SignInWithEmailUseCase
class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}
