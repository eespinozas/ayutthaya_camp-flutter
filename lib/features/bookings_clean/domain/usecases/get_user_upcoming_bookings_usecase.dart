import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

/// Get User Upcoming Bookings Use Case
/// Single Responsibility: Retrieve user's upcoming bookings as a stream
class GetUserUpcomingBookingsUseCase
    implements
        StreamUseCase<Either<Failure, List<BookingEntity>>,
            GetUserUpcomingBookingsParams> {
  final BookingRepository repository;

  GetUserUpcomingBookingsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<BookingEntity>>> call(
      GetUserUpcomingBookingsParams params) {
    // Business logic validation
    if (params.userId.isEmpty) {
      return Stream.value(
        Left(ValidationFailure('ID de usuario inválido')),
      );
    }

    // Delegate to repository
    return repository.getUserUpcomingBookings(userId: params.userId);
  }
}

/// Parameters for GetUserUpcomingBookingsUseCase
class GetUserUpcomingBookingsParams extends Equatable {
  final String userId;

  const GetUserUpcomingBookingsParams({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}
