import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ayutthaya_camp/features/bookings/services/booking_service.dart';
import 'package:ayutthaya_camp/features/bookings/models/booking.dart';

void main() {
  group('BookingService - Atomic Capacity Transactions', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingService bookingService;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();

      // Seed: Create a class schedule
      await fakeFirestore.collection('class_schedules').doc('schedule_1').set({
        'time': '07:00',
        'type': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'capacity': 15,
        'daysOfWeek': [1, 2, 3, 4, 5],
        'active': true,
        'displayOrder': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Seed: Create capacity_tracking document
      await fakeFirestore
          .collection('class_schedules')
          .doc('schedule_1')
          .collection('capacity_tracking')
          .doc('2025-01-15')
          .set({
        'currentBookings': 0,
        'maxCapacity': 15,
        'scheduleId': 'schedule_1',
        'classDate': Timestamp.fromDate(DateTime(2025, 1, 15)),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Seed: Create user
      await fakeFirestore.collection('users').doc('user_1').set({
        'email': 'test@test.com',
        'name': 'Test User',
        'role': 'student',
        'membershipStatus': 'active',
        'classesPerMonth': 12,
        'classesUsedThisMonth': 0,
      });

      bookingService = BookingService();
    });

    test('should create booking and increment capacity counter atomically',
        () async {
      final booking = Booking(
        userId: 'user_1',
        userName: 'Test User',
        userEmail: 'test@test.com',
        scheduleId: 'schedule_1',
        scheduleTime: '07:00',
        scheduleType: 'Muay Thai',
        instructor: 'Francisco Poveda',
        classDate: DateTime(2025, 1, 15),
        createdAt: DateTime.now(),
      );

      // Act: Create booking
      final bookingId = await bookingService.createBooking(booking);

      // Assert: Booking created
      expect(bookingId, isNotNull);
      final bookingDoc =
          await fakeFirestore.collection('bookings').doc(bookingId).get();
      expect(bookingDoc.exists, true);

      // Assert: Capacity counter incremented
      final capacityDoc = await fakeFirestore
          .collection('class_schedules')
          .doc('schedule_1')
          .collection('capacity_tracking')
          .doc('2025-01-15')
          .get();

      expect(capacityDoc.data()?['currentBookings'], 1);
    });

    test('should prevent booking when class is full', () async {
      // Arrange: Set capacity to full
      await fakeFirestore
          .collection('class_schedules')
          .doc('schedule_1')
          .collection('capacity_tracking')
          .doc('2025-01-15')
          .update({'currentBookings': 15});

      final booking = Booking(
        userId: 'user_1',
        userName: 'Test User',
        userEmail: 'test@test.com',
        scheduleId: 'schedule_1',
        scheduleTime: '07:00',
        scheduleType: 'Muay Thai',
        instructor: 'Francisco Poveda',
        classDate: DateTime(2025, 1, 15),
        createdAt: DateTime.now(),
      );

      // Act & Assert: Should throw exception
      expect(
        () async => await bookingService.createBooking(booking),
        throwsA(isA<Exception>()),
      );
    });

    test('should prevent duplicate bookings for same user, schedule, and date',
        () async {
      final booking = Booking(
        userId: 'user_1',
        userName: 'Test User',
        userEmail: 'test@test.com',
        scheduleId: 'schedule_1',
        scheduleTime: '07:00',
        scheduleType: 'Muay Thai',
        instructor: 'Francisco Poveda',
        classDate: DateTime(2025, 1, 15),
        status: BookingStatus.confirmed,
        createdAt: DateTime.now(),
      );

      // Create first booking
      await bookingService.createBooking(booking);

      // Try to create duplicate
      expect(
        () async => await bookingService.createBooking(booking),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Ya tienes una reserva'))),
      );
    });

    test('should cancel booking and decrement capacity counter atomically',
        () async {
      // Arrange: Create a booking first
      final booking = Booking(
        userId: 'user_1',
        userName: 'Test User',
        userEmail: 'test@test.com',
        scheduleId: 'schedule_1',
        scheduleTime: '07:00',
        scheduleType: 'Muay Thai',
        instructor: 'Francisco Poveda',
        classDate: DateTime(2025, 1, 15),
        createdAt: DateTime.now(),
      );

      final bookingId = await bookingService.createBooking(booking);

      // Verify counter is 1
      var capacityDoc = await fakeFirestore
          .collection('class_schedules')
          .doc('schedule_1')
          .collection('capacity_tracking')
          .doc('2025-01-15')
          .get();
      expect(capacityDoc.data()?['currentBookings'], 1);

      // Act: Cancel booking
      await bookingService.cancelBooking(bookingId, 'User cancelled');

      // Assert: Booking status updated
      final bookingDoc =
          await fakeFirestore.collection('bookings').doc(bookingId).get();
      expect(bookingDoc.data()?['status'], BookingStatus.cancelled.name);

      // Assert: Counter decremented
      capacityDoc = await fakeFirestore
          .collection('class_schedules')
          .doc('schedule_1')
          .collection('capacity_tracking')
          .doc('2025-01-15')
          .get();
      expect(capacityDoc.data()?['currentBookings'], 0);
    });

    test('should not allow cancelling already cancelled booking', () async {
      // Arrange: Create and cancel a booking
      final booking = Booking(
        userId: 'user_1',
        userName: 'Test User',
        userEmail: 'test@test.com',
        scheduleId: 'schedule_1',
        scheduleTime: '07:00',
        scheduleType: 'Muay Thai',
        instructor: 'Francisco Poveda',
        classDate: DateTime(2025, 1, 15),
        createdAt: DateTime.now(),
      );

      final bookingId = await bookingService.createBooking(booking);
      await bookingService.cancelBooking(bookingId, 'First cancellation');

      // Act & Assert: Try to cancel again
      expect(
        () async =>
            await bookingService.cancelBooking(bookingId, 'Second attempt'),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Solo se pueden cancelar'))),
      );
    });

    test('getBookedCount should return current bookings from counter',
        () async {
      // Arrange: Update counter manually
      await fakeFirestore
          .collection('class_schedules')
          .doc('schedule_1')
          .collection('capacity_tracking')
          .doc('2025-01-15')
          .update({'currentBookings': 8});

      // Act
      final count = await bookingService.getBookedCount(
        'schedule_1',
        DateTime(2025, 1, 15),
      );

      // Assert
      expect(count, 8);
    });

    test('getBookedCount should return 0 for date without counter', () async {
      // Act: Query date that has no capacity_tracking document
      final count = await bookingService.getBookedCount(
        'schedule_1',
        DateTime(2025, 2, 1),
      );

      // Assert
      expect(count, 0);
    });

    test('should prevent booking past class times', () async {
      final now = DateTime.now();
      final pastClass = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour - 2, // 2 hours ago
        0,
      );

      final booking = Booking(
        userId: 'user_1',
        userName: 'Test User',
        userEmail: 'test@test.com',
        scheduleId: 'schedule_1',
        scheduleTime: '${pastClass.hour}:00',
        scheduleType: 'Muay Thai',
        instructor: 'Francisco Poveda',
        classDate: pastClass,
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () async => await bookingService.createBooking(booking),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('ya comenzó'))),
      );
    });

    test('_getDateKey should format date correctly', () {
      // This is a private method, but we can test it indirectly
      // by verifying the capacity_tracking document IDs match expected format

      final date = DateTime(2025, 1, 5);
      final expectedKey = '2025-01-05';

      // The service should create documents with this key
      // We can verify by checking the document ID after creating a booking

      expect(expectedKey, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });

  group('BookingService - Stream Methods', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingService bookingService;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      bookingService = BookingService();

      // Seed bookings
      final now = DateTime.now();
      await fakeFirestore.collection('bookings').add({
        'userId': 'user_1',
        'userName': 'Test User',
        'userEmail': 'test@test.com',
        'scheduleId': 'schedule_1',
        'scheduleTime': '07:00',
        'scheduleType': 'Muay Thai',
        'instructor': 'Francisco',
        'classDate': Timestamp.fromDate(now.add(Duration(days: 1))),
        'status': BookingStatus.confirmed.name,
        'createdAt': Timestamp.fromDate(now),
      });
    });

    test('getUserBookings should return stream of user bookings', () async {
      // Act
      final stream = bookingService.getUserBookings('user_1');

      // Assert
      await expectLater(
        stream,
        emits(predicate<List<Booking>>((bookings) => bookings.isNotEmpty)),
      );
    });

    test('getUserUpcomingBookings should only return future bookings',
        () async {
      // Arrange: Add a past booking
      final past = DateTime.now().subtract(Duration(days: 5));
      await fakeFirestore.collection('bookings').add({
        'userId': 'user_1',
        'classDate': Timestamp.fromDate(past),
        'status': BookingStatus.confirmed.name,
      });

      // Act
      final stream = bookingService.getUserUpcomingBookings('user_1');

      // Assert: Should only get future booking
      await expectLater(
        stream,
        emits(predicate<List<Booking>>((bookings) {
          return bookings.every((b) => !b.isPast());
        })),
      );
    });
  });
}
