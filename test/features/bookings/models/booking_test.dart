import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ayutthaya_camp/features/bookings/models/booking.dart';

void main() {
  group('Booking Model', () {
    late Booking testBooking;

    setUp(() {
      testBooking = Booking(
        id: 'booking_123',
        userId: 'user_1',
        userName: 'Test User',
        userEmail: 'test@test.com',
        scheduleId: 'schedule_1',
        scheduleTime: '07:00',
        scheduleType: 'Muay Thai',
        instructor: 'Francisco Poveda',
        classDate: DateTime(2025, 1, 15, 0, 0, 0),
        status: BookingStatus.confirmed,
        createdAt: DateTime(2025, 1, 10),
      );
    });

    group('Helper Methods', () {
      test('isToday should return true when class is today', () {
        final today = DateTime.now();
        final todayBooking = testBooking.copyWith(
          classDate: DateTime(today.year, today.month, today.day),
        );

        expect(todayBooking.isToday(), true);
      });

      test('isToday should return false when class is not today', () {
        final tomorrow = DateTime.now().add(Duration(days: 1));
        final futureBooking = testBooking.copyWith(
          classDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
        );

        expect(futureBooking.isToday(), false);
      });

      test('isFuture should return true for future dates', () {
        final tomorrow = DateTime.now().add(Duration(days: 1));
        final futureBooking = testBooking.copyWith(
          classDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
        );

        expect(futureBooking.isFuture(), true);
      });

      test('isPast should return true for past dates', () {
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        final pastBooking = testBooking.copyWith(
          classDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
        );

        expect(pastBooking.isPast(), true);
      });
    });

    group('Attendance Confirmation', () {
      test('canConfirmAttendance should return true within 30min window',
          () {
        final now = DateTime.now();

        // Class starting in 15 minutes
        final upcomingBooking = testBooking.copyWith(
          classDate: DateTime(now.year, now.month, now.day),
          scheduleTime: '${now.hour}:${now.minute + 15}',
        );

        expect(upcomingBooking.canConfirmAttendance(), true);
      });

      test(
          'canConfirmAttendance should return false if already user confirmed',
          () {
        final now = DateTime.now();
        final confirmedBooking = testBooking.copyWith(
          classDate: DateTime(now.year, now.month, now.day),
          scheduleTime: '${now.hour}:${now.minute}',
          userConfirmedAttendance: true,
        );

        expect(confirmedBooking.canConfirmAttendance(), false);
      });

      test('canConfirmAttendance should return false if not confirmed status',
          () {
        final now = DateTime.now();
        final cancelledBooking = testBooking.copyWith(
          classDate: DateTime(now.year, now.month, now.day),
          scheduleTime: '${now.hour}:${now.minute}',
          status: BookingStatus.cancelled,
        );

        expect(cancelledBooking.canConfirmAttendance(), false);
      });

      test('missedConfirmationWindow should return true after 30min window',
          () {
        final now = DateTime.now();

        // Class was 1 hour ago
        final pastBooking = testBooking.copyWith(
          classDate: DateTime(now.year, now.month, now.day),
          scheduleTime: '${now.hour - 1}:${now.minute}',
          userConfirmedAttendance: false,
        );

        expect(pastBooking.missedConfirmationWindow(), true);
      });

      test('getConfirmationStatusText should return correct status', () {
        // Confirmed by user
        expect(
          testBooking
              .copyWith(userConfirmedAttendance: true)
              .getConfirmationStatusText(),
          'Confirmada',
        );

        // Attended
        expect(
          testBooking
              .copyWith(status: BookingStatus.attended)
              .getConfirmationStatusText(),
          'Asistió',
        );

        // Cancelled
        expect(
          testBooking
              .copyWith(status: BookingStatus.cancelled)
              .getConfirmationStatusText(),
          'Cancelada',
        );

        // No show
        expect(
          testBooking
              .copyWith(status: BookingStatus.noShow)
              .getConfirmationStatusText(),
          'No asistió',
        );
      });
    });

    group('Serialization', () {
      test('toMap should convert booking to Firestore map', () {
        final map = testBooking.toMap();

        expect(map['userId'], 'user_1');
        expect(map['userName'], 'Test User');
        expect(map['userEmail'], 'test@test.com');
        expect(map['scheduleId'], 'schedule_1');
        expect(map['scheduleTime'], '07:00');
        expect(map['scheduleType'], 'Muay Thai');
        expect(map['instructor'], 'Francisco Poveda');
        expect(map['status'], BookingStatus.confirmed.name);
        expect(map['classDate'], isA<Timestamp>());
        expect(map['createdAt'], isA<Timestamp>());
      });

      test('toMap should handle null optional fields', () {
        final booking = Booking(
          userId: 'user_1',
          userName: 'Test',
          userEmail: 'test@test.com',
          scheduleId: 'schedule_1',
          scheduleTime: '07:00',
          scheduleType: 'Muay Thai',
          instructor: 'Francisco',
          classDate: DateTime(2025, 1, 15),
          createdAt: DateTime.now(),
        );

        final map = booking.toMap();

        expect(map['updatedAt'], null);
        expect(map['cancelledAt'], null);
        expect(map['cancellationReason'], null);
        expect(map['attendedAt'], null);
        expect(map['attendedBy'], null);
      });
    });

    group('copyWith', () {
      test('should create a copy with updated values', () {
        final updated = testBooking.copyWith(
          status: BookingStatus.attended,
          attendedAt: DateTime(2025, 1, 15, 7, 30),
          attendedBy: 'admin_1',
        );

        expect(updated.id, testBooking.id);
        expect(updated.userId, testBooking.userId);
        expect(updated.status, BookingStatus.attended);
        expect(updated.attendedAt, DateTime(2025, 1, 15, 7, 30));
        expect(updated.attendedBy, 'admin_1');
      });

      test('should keep original values when not specified', () {
        final updated = testBooking.copyWith(status: BookingStatus.cancelled);

        expect(updated.userName, testBooking.userName);
        expect(updated.scheduleTime, testBooking.scheduleTime);
        expect(updated.classDate, testBooking.classDate);
      });
    });

    group('BookingStatus enum', () {
      test('should have correct values', () {
        expect(BookingStatus.confirmed.name, 'confirmed');
        expect(BookingStatus.attended.name, 'attended');
        expect(BookingStatus.cancelled.name, 'cancelled');
        expect(BookingStatus.noShow.name, 'noShow');
      });

      test('should parse from string correctly', () {
        expect(
          BookingStatus.values.firstWhere((e) => e.name == 'confirmed'),
          BookingStatus.confirmed,
        );
        expect(
          BookingStatus.values.firstWhere((e) => e.name == 'attended'),
          BookingStatus.attended,
        );
      });
    });
  });
}
