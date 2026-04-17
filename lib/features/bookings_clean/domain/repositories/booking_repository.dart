import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';

/// Booking Repository Interface (Domain Layer)
/// Defines contracts for booking operations
/// Implementation details are in the Data layer
abstract class BookingRepository {
  /// Create a new booking
  Future<Either<Failure, String>> createBooking(BookingEntity booking);

  /// Cancel a booking
  Future<Either<Failure, void>> cancelBooking({
    required String bookingId,
    required String reason,
  });

  /// Mark attendance (admin)
  Future<Either<Failure, void>> markAttendance({
    required String bookingId,
    required String adminId,
  });

  /// Mark no-show (admin)
  Future<Either<Failure, void>> markNoShow({
    required String bookingId,
    required String adminId,
  });

  /// Confirm attendance (user)
  Future<Either<Failure, void>> confirmAttendance({
    required String bookingId,
  });

  /// Get user bookings as stream
  Stream<Either<Failure, List<BookingEntity>>> getUserBookings({
    required String userId,
  });

  /// Get user upcoming bookings as stream
  Stream<Either<Failure, List<BookingEntity>>> getUserUpcomingBookings({
    required String userId,
  });

  /// Get class bookings (for admin)
  Stream<Either<Failure, List<BookingEntity>>> getClassBookings({
    required String scheduleId,
    required DateTime classDate,
  });

  /// Get bookings by date (for admin)
  Stream<Either<Failure, List<BookingEntity>>> getBookingsByDate({
    required DateTime date,
  });

  /// Check if user has booking for class
  Future<Either<Failure, bool>> hasBookingForClass({
    required String userId,
    required String scheduleId,
    required DateTime classDate,
  });

  /// Get booked count for a class
  Future<Either<Failure, int>> getBookedCount({
    required String scheduleId,
    required DateTime classDate,
  });

  /// Get user attendance statistics
  Future<Either<Failure, Map<String, int>>> getUserAttendanceStats({
    required String userId,
  });

  /// Get user booked classes this month
  Future<Either<Failure, int>> getUserBookedClassesThisMonth({
    required String userId,
    required DateTime referenceDate,
  });

  /// Process QR check-in
  Future<Either<Failure, Map<String, dynamic>>> processQRCheckIn({
    required String userId,
    required String userName,
    required String userEmail,
  });

  /// Process expired confirmations
  Future<Either<Failure, void>> processExpiredConfirmations();
}
