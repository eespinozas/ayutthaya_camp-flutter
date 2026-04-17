import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

/// Get User Bookings Use Case
/// Single Responsibility: Retrieve all user bookings as a stream
class GetUserBookingsUseCase
    implements StreamUseCase<Either<Failure, List<BookingEntity>>, GetUserBookingsParams> {
  final BookingRepository repository;

  GetUserBookingsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<BookingEntity>>> call(GetUserBookingsParams params) {
    // Business logic validation
    if (params.userId.isEmpty) {
      return Stream.value(
        Left(ValidationFailure('ID de usuario inválido')),
      );
    }

    // Delegate to repository
    return repository.getUserBookings(userId: params.userId);
  }
}

/// Parameters for GetUserBookingsUseCase
class GetUserBookingsParams extends Equatable {
  final String userId;

  const GetUserBookingsParams({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}
