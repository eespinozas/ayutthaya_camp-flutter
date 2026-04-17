import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

/// Cancel Booking Use Case
/// Single Responsibility: Handle booking cancellation logic
class CancelBookingUseCase implements UseCase<void, CancelBookingParams> {
  final BookingRepository repository;

  CancelBookingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelBookingParams params) async {
    // Business logic validation
    if (params.bookingId.isEmpty) {
      return Left(ValidationFailure('ID de reserva inválido'));
    }

    if (params.reason.isEmpty) {
      return Left(ValidationFailure('Debe proporcionar una razón de cancelación'));
    }

    if (params.reason.length < 3) {
      return Left(ValidationFailure('La razón debe tener al menos 3 caracteres'));
    }

    // Delegate to repository
    return await repository.cancelBooking(
      bookingId: params.bookingId,
      reason: params.reason,
    );
  }
}

/// Parameters for CancelBookingUseCase
class CancelBookingParams extends Equatable {
  final String bookingId;
  final String reason;

  const CancelBookingParams({
    required this.bookingId,
    required this.reason,
  });

  @override
  List<Object?> get props => [bookingId, reason];
}
