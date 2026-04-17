import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

/// Create Booking Use Case
/// Single Responsibility: Handle booking creation logic
class CreateBookingUseCase implements UseCase<String, CreateBookingParams> {
  final BookingRepository repository;

  CreateBookingUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateBookingParams params) async {
    // Business logic validation
    if (!_isValidScheduleTime(params.booking.scheduleTime)) {
      return Left(ValidationFailure('Formato de hora inválido'));
    }

    if (params.booking.classDate.isBefore(DateTime.now())) {
      return Left(ValidationFailure('No puedes agendar una clase en el pasado'));
    }

    // Delegate to repository
    return await repository.createBooking(params.booking);
  }

  bool _isValidScheduleTime(String time) {
    // Validate HH:mm format
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }
}

/// Parameters for CreateBookingUseCase
class CreateBookingParams extends Equatable {
  final BookingEntity booking;

  const CreateBookingParams({
    required this.booking,
  });

  @override
  List<Object?> get props => [booking];
}
