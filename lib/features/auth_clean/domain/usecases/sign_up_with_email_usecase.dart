import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Sign Up with Email Use Case
class SignUpWithEmailUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  SignUpWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    // Validation
    if (!_isEmailValid(params.email)) {
      return Left(ValidationFailure('Email inválido'));
    }

    if (!_isPasswordValid(params.password)) {
      return Left(ValidationFailure('Contraseña debe tener al menos 6 caracteres'));
    }

    if (params.name.trim().isEmpty) {
      return Left(ValidationFailure('Nombre es requerido'));
    }

    return await repository.signUpWithEmail(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    return password.length >= 6;
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String name;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}
