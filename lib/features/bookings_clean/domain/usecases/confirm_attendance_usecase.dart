import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

/// Confirm Attendance Use Case (User)
/// Single Responsibility: Handle user attendance confirmation logic
class ConfirmAttendanceUseCase implements UseCase<void, ConfirmAttendanceParams> {
  final BookingRepository repository;

  ConfirmAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ConfirmAttendanceParams params) async {
    // Business logic validation
    if (params.bookingId.isEmpty) {
      return Left(ValidationFailure('ID de reserva inválido'));
    }

    // Delegate to repository
    return await repository.confirmAttendance(
      bookingId: params.bookingId,
    );
  }
}

/// Parameters for ConfirmAttendanceUseCase
class ConfirmAttendanceParams extends Equatable {
  final String bookingId;

  const ConfirmAttendanceParams({
    required this.bookingId,
  });

  @override
  List<Object?> get props => [bookingId];
}
