import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

/// Check In Use Case (QR Code)
/// Single Responsibility: Handle QR check-in process logic
class CheckInUseCase implements UseCase<Map<String, dynamic>, CheckInParams> {
  final BookingRepository repository;

  CheckInUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(CheckInParams params) async {
    // Business logic validation
    if (params.userId.isEmpty) {
      return Left(ValidationFailure('ID de usuario inválido'));
    }

    if (params.userName.isEmpty) {
      return Left(ValidationFailure('Nombre de usuario requerido'));
    }

    if (params.userEmail.isEmpty || !_isEmailValid(params.userEmail)) {
      return Left(ValidationFailure('Email de usuario inválido'));
    }

    // Delegate to repository
    return await repository.processQRCheckIn(
      userId: params.userId,
      userName: params.userName,
      userEmail: params.userEmail,
    );
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Parameters for CheckInUseCase
class CheckInParams extends Equatable {
  final String userId;
  final String userName;
  final String userEmail;

  const CheckInParams({
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  List<Object?> get props => [userId, userName, userEmail];
}
