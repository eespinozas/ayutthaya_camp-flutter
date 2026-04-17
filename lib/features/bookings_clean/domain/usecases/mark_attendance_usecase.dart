import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

/// Mark Attendance Use Case (Admin)
/// Single Responsibility: Handle attendance marking logic
class MarkAttendanceUseCase implements UseCase<void, MarkAttendanceParams> {
  final BookingRepository repository;

  MarkAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkAttendanceParams params) async {
    // Business logic validation
    if (params.bookingId.isEmpty) {
      return Left(ValidationFailure('ID de reserva inválido'));
    }

    if (params.adminId.isEmpty) {
      return Left(ValidationFailure('ID de administrador inválido'));
    }

    // Delegate to repository
    return await repository.markAttendance(
      bookingId: params.bookingId,
      adminId: params.adminId,
    );
  }
}

/// Parameters for MarkAttendanceUseCase
class MarkAttendanceParams extends Equatable {
  final String bookingId;
  final String adminId;

  const MarkAttendanceParams({
    required this.bookingId,
    required this.adminId,
  });

  @override
  List<Object?> get props => [bookingId, adminId];
}
