import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/booking_model.dart';

/// Booking Repository Implementation (Data Layer)
/// Implements BookingRepository interface
/// Handles error conversion and data transformation
class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, String>> createBooking(BookingEntity booking) async {
    try {
      final bookingModel = BookingModel.fromEntity(booking);
      final bookingId = await remoteDataSource.createBooking(bookingModel);
      return Right(bookingId);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    try {
      await remoteDataSource.cancelBooking(bookingId, reason);
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> markAttendance({
    required String bookingId,
    required String adminId,
  }) async {
    try {
      await remoteDataSource.markAttendance(bookingId, adminId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> markNoShow({
    required String bookingId,
    required String adminId,
  }) async {
    try {
      await remoteDataSource.markNoShow(bookingId, adminId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> confirmAttendance({
    required String bookingId,
  }) async {
    try {
      await remoteDataSource.confirmAttendance(bookingId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Stream<Either<Failure, List<BookingEntity>>> getUserBookings({
    required String userId,
  }) {
    try {
      return remoteDataSource.getUserBookings(userId).map(
            (bookings) => Right<Failure, List<BookingEntity>>(
              bookings.map((model) => model.toEntity()).toList(),
            ),
          );
    } on Exception catch (e) {
      return Stream.value(Left(_handleException(e)));
    }
  }

  @override
  Stream<Either<Failure, List<BookingEntity>>> getUserUpcomingBookings({
    required String userId,
  }) {
    try {
      return remoteDataSource.getUserUpcomingBookings(userId).map(
            (bookings) => Right<Failure, List<BookingEntity>>(
              bookings.map((model) => model.toEntity()).toList(),
            ),
          );
    } on Exception catch (e) {
      return Stream.value(Left(_handleException(e)));
    }
  }

  @override
  Stream<Either<Failure, List<BookingEntity>>> getClassBookings({
    required String scheduleId,
    required DateTime classDate,
  }) {
    try {
      return remoteDataSource.getClassBookings(scheduleId, classDate).map(
            (bookings) => Right<Failure, List<BookingEntity>>(
              bookings.map((model) => model.toEntity()).toList(),
            ),
          );
    } on Exception catch (e) {
      return Stream.value(Left(_handleException(e)));
    }
  }

  @override
  Stream<Either<Failure, List<BookingEntity>>> getBookingsByDate({
    required DateTime date,
  }) {
    try {
      return remoteDataSource.getBookingsByDate(date).map(
            (bookings) => Right<Failure, List<BookingEntity>>(
              bookings.map((model) => model.toEntity()).toList(),
            ),
          );
    } on Exception catch (e) {
      return Stream.value(Left(_handleException(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> hasBookingForClass({
    required String userId,
    required String scheduleId,
    required DateTime classDate,
  }) async {
    try {
      final hasBooking =
          await remoteDataSource.hasBookingForClass(userId, scheduleId, classDate);
      return Right(hasBooking);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, int>> getBookedCount({
    required String scheduleId,
    required DateTime classDate,
  }) async {
    try {
      final count = await remoteDataSource.getBookedCount(scheduleId, classDate);
      return Right(count);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getUserAttendanceStats({
    required String userId,
  }) async {
    try {
      final stats = await remoteDataSource.getUserAttendanceStats(userId);
      return Right(stats);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, int>> getUserBookedClassesThisMonth({
    required String userId,
    required DateTime referenceDate,
  }) async {
    try {
      final count =
          await remoteDataSource.getUserBookedClassesThisMonth(userId, referenceDate);
      return Right(count);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> processQRCheckIn({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      final result = await remoteDataSource.processQRCheckIn(userId, userName, userEmail);
      return Right(result);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> processExpiredConfirmations() async {
    try {
      await remoteDataSource.processExpiredConfirmations();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  /// Handle exceptions and convert to appropriate Failure types
  Failure _handleException(Exception exception) {
    final message = exception.toString().replaceAll('Exception: ', '');

    // Check for specific error types
    if (message.contains('llena') || message.contains('límite')) {
      return ValidationFailure(message);
    }

    if (message.contains('no encontrado') || message.contains('not found')) {
      return ServerFailure(message, code: 'not_found');
    }

    if (message.contains('permission') || message.contains('permisos')) {
      return PermissionFailure(message);
    }

    if (message.contains('network') || message.contains('conexión')) {
      return NetworkFailure(message);
    }

    // Default to server failure
    return ServerFailure(message);
  }
}
