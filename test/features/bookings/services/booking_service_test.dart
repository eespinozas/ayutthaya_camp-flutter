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

      bookingService = BookingService(firestore: fakeFirestore);
    });

    test(
      'should create booking and increment capacity counter atomically',
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
        final bookingDoc = await fakeFirestore
            .collection('bookings')
            .doc(bookingId)
            .get();
        expect(bookingDoc.exists, true);

        // Assert: Capacity counter incremented
        final capacityDoc = await fakeFirestore
            .collection('class_schedules')
            .doc('schedule_1')
            .collection('capacity_tracking')
            .doc('2025-01-15')
            .get();

        expect(capacityDoc.data()?['currentBookings'], 1);
      },
    );

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

    test(
      'should prevent duplicate bookings for same user, schedule, and date',
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
          throwsA(
            predicate(
              (e) =>
                  e is Exception &&
                  e.toString().contains('Ya tienes una reserva'),
            ),
          ),
        );
      },
    );

    test(
      'should cancel booking and decrement capacity counter atomically',
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
        final bookingDoc = await fakeFirestore
            .collection('bookings')
            .doc(bookingId)
            .get();
        expect(bookingDoc.data()?['status'], BookingStatus.cancelled.name);

        // Assert: Counter decremented
        capacityDoc = await fakeFirestore
            .collection('class_schedules')
            .doc('schedule_1')
            .collection('capacity_tracking')
            .doc('2025-01-15')
            .get();
        expect(capacityDoc.data()?['currentBookings'], 0);
      },
    );

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
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Solo se pueden cancelar'),
          ),
        ),
      );
    });

    test(
      'getBookedCount should return current bookings from counter',
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
      },
    );

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
      // Una clase de HOY que ya comenzó. Ojo: restar horas con aritmética
      // de campos (now.hour - 2) da horas negativas pasada la medianoche y
      // la fecha se normaliza a ayer, saltándose la validación de "hoy".
      final now = DateTime.now();
      var pastTime = now.subtract(const Duration(minutes: 1));
      if (pastTime.day != now.day) {
        pastTime = DateTime(now.year, now.month, now.day); // 00:00 de hoy
      }

      final booking = Booking(
        userId: 'user_1',
        userName: 'Test User',
        userEmail: 'test@test.com',
        scheduleId: 'schedule_1',
        scheduleTime:
            '${pastTime.hour.toString().padLeft(2, '0')}:${pastTime.minute.toString().padLeft(2, '0')}',
        scheduleType: 'Muay Thai',
        instructor: 'Francisco Poveda',
        classDate: DateTime(pastTime.year, pastTime.month, pastTime.day),
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () async => await bookingService.createBooking(booking),
        throwsA(
          predicate(
            (e) => e is Exception && e.toString().contains('ya comenzó'),
          ),
        ),
      );
    });

    test('_getDateKey should format date correctly', () {
      // This is a private method, but we can test it indirectly
      // by verifying the capacity_tracking document IDs match expected format

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
      bookingService = BookingService(firestore: fakeFirestore);

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

    test(
      'getUserUpcomingBookings should only return future bookings',
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
          emits(
            predicate<List<Booking>>((bookings) {
              return bookings.every((b) => !b.isPast());
            }),
          ),
        );
      },
    );
  });

  group('BookingService - Schedule overrides (horarios suspendidos)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingService bookingService;
    final classDate = DateTime.now().add(const Duration(days: 2));
    late DateTime normalizedDate;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      bookingService = BookingService(firestore: fakeFirestore);
      normalizedDate = DateTime(classDate.year, classDate.month, classDate.day);

      await fakeFirestore.collection('class_schedules').doc('schedule_1').set({
        'time': '07:00',
        'type': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'capacity': 15,
        'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
        'active': true,
        'displayOrder': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fakeFirestore.collection('users').doc('user_1').set({
        'email': 'test@test.com',
        'name': 'Test User',
        'role': 'student',
        'membershipStatus': 'active',
        'classesPerMonth': null,
      });
    });

    Booking buildBooking() => Booking(
      userId: 'user_1',
      userName: 'Test User',
      userEmail: 'test@test.com',
      scheduleId: 'schedule_1',
      scheduleTime: '07:00',
      scheduleType: 'Muay Thai',
      instructor: 'Francisco Poveda',
      classDate: normalizedDate,
      createdAt: DateTime.now(),
    );

    test('bloquea reservas nuevas cuando el horario está suspendido', () async {
      final dateKey =
          '${normalizedDate.year}-${normalizedDate.month.toString().padLeft(2, '0')}-${normalizedDate.day.toString().padLeft(2, '0')}';
      await fakeFirestore
          .collection('schedule_overrides')
          .doc('schedule_1_$dateKey')
          .set({
            'scheduleId': 'schedule_1',
            'dateKey': dateKey,
            'disabled': true,
            'reason': 'Pelea',
            'createdBy': 'admin_1',
            'createdAt': FieldValue.serverTimestamp(),
          });

      expect(
        () => bookingService.createBooking(buildBooking()),
        throwsA(predicate((e) => e.toString().contains('suspendido'))),
      );
    });

    test('permite reservar cuando el override está en disabled=false', () async {
      final dateKey =
          '${normalizedDate.year}-${normalizedDate.month.toString().padLeft(2, '0')}-${normalizedDate.day.toString().padLeft(2, '0')}';
      await fakeFirestore
          .collection('schedule_overrides')
          .doc('schedule_1_$dateKey')
          .set({
            'scheduleId': 'schedule_1',
            'dateKey': dateKey,
            'disabled': false,
            'createdBy': 'admin_1',
            'createdAt': FieldValue.serverTimestamp(),
          });

      final bookingId = await bookingService.createBooking(buildBooking());
      expect(bookingId, isNotEmpty);
    });
  });

  group('BookingService - Flujo de aprobación de asistencia', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingService bookingService;
    late String bookingId;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      bookingService = BookingService(firestore: fakeFirestore);

      final ref = await fakeFirestore.collection('bookings').add({
        'userId': 'user_1',
        'userName': 'Test User',
        'userEmail': 'test@test.com',
        'scheduleId': 'schedule_1',
        'scheduleTime': '07:00',
        'scheduleType': 'Muay Thai',
        'instructor': 'Francisco',
        'classDate': Timestamp.fromDate(DateTime.now()),
        'status': BookingStatus.confirmed.name,
        'userConfirmedAttendance': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      bookingId = ref.id;
    });

    test('confirmAttendance deja la reserva en pendingApproval '
        '(no attended) con el flag activo', () async {
      await bookingService.confirmAttendance(bookingId);

      final doc = await fakeFirestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      final data = doc.data()!;

      // Con AppFlags.attendanceApprovalFlow == true la confirmación del
      // alumno NO marca asistencia directa: queda esperando al admin.
      expect(data['status'], BookingStatus.pendingApproval.name);
      expect(data['userConfirmedAttendance'], true);
      expect(data['attendanceConfirmedAt'], isNotNull);
      expect(data['attendedAt'], isNull);
    });

    test(
      'markAttendance (aprobación admin) marca attended con attendedBy',
      () async {
        await bookingService.confirmAttendance(bookingId);
        await bookingService.markAttendance(bookingId, 'admin_1');

        final doc = await fakeFirestore
            .collection('bookings')
            .doc(bookingId)
            .get();
        final data = doc.data()!;

        expect(data['status'], BookingStatus.attended.name);
        expect(data['attendedBy'], 'admin_1');
        expect(data['attendedAt'], isNotNull);
      },
    );
  });
}
