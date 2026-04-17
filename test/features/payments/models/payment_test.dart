import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ayutthaya_camp/features/payments/models/payment.dart';

void main() {
  group('Payment Model', () {
    late Payment testPayment;

    setUp(() {
      testPayment = Payment(
        id: 'payment_123',
        userId: 'user_1',
        userName: 'Test User',
        userEmail: 'test@test.com',
        type: PaymentType.enrollment,
        amount: 50000.0,
        plan: 'Mensual',
        paymentDate: DateTime(2025, 1, 10),
        receiptUrl: 'https://storage.googleapis.com/receipt.jpg',
        status: PaymentStatus.pending,
        createdAt: DateTime(2025, 1, 10),
      );
    });

    group('Payment Enums', () {
      test('PaymentType should have correct values', () {
        expect(PaymentType.enrollment.name, 'enrollment');
        expect(PaymentType.monthly.name, 'monthly');
      });

      test('PaymentStatus should have all required states', () {
        expect(PaymentStatus.pending.name, 'pending');
        expect(PaymentStatus.approved.name, 'approved');
        expect(PaymentStatus.rejected.name, 'rejected');
        expect(PaymentStatus.failed.name, 'failed');
      });
    });

    group('Serialization', () {
      test('toMap should convert payment to Firestore map', () {
        final map = testPayment.toMap();

        expect(map['userId'], 'user_1');
        expect(map['userName'], 'Test User');
        expect(map['userEmail'], 'test@test.com');
        expect(map['type'], 'enrollment');
        expect(map['amount'], 50000.0);
        expect(map['plan'], 'Mensual');
        expect(map['receiptUrl'],
            'https://storage.googleapis.com/receipt.jpg');
        expect(map['status'], 'pending');
        expect(map['paymentDate'], isA<Timestamp>());
        expect(map['createdAt'], isA<Timestamp>());
      });

      test('toMap should handle optional fields correctly', () {
        final payment = Payment(
          userId: 'user_1',
          userName: 'Test User',
          userEmail: 'test@test.com',
          type: PaymentType.monthly,
          amount: 35000.0,
          plan: 'Mensual',
          paymentDate: DateTime(2025, 1, 10),
          receiptUrl: 'https://url.com',
          createdAt: DateTime(2025, 1, 10),
        );

        final map = payment.toMap();

        expect(map['rejectionReason'], null);
        expect(map['reviewedBy'], null);
        expect(map['reviewedAt'], null);
      });

      test('toMap should include approval fields when provided', () {
        final approvedPayment = Payment(
          userId: 'user_1',
          userName: 'Test User',
          userEmail: 'test@test.com',
          type: PaymentType.monthly,
          amount: 35000.0,
          plan: 'Mensual',
          paymentDate: DateTime(2025, 1, 10),
          receiptUrl: 'https://url.com',
          status: PaymentStatus.approved,
          reviewedBy: 'admin_1',
          reviewedAt: DateTime(2025, 1, 11),
          createdAt: DateTime(2025, 1, 10),
        );

        final map = approvedPayment.toMap();

        expect(map['status'], 'approved');
        expect(map['reviewedBy'], 'admin_1');
        expect(map['reviewedAt'], isA<Timestamp>());
      });

      test('toMap should include rejection fields when rejected', () {
        final rejectedPayment = Payment(
          userId: 'user_1',
          userName: 'Test User',
          userEmail: 'test@test.com',
          type: PaymentType.monthly,
          amount: 35000.0,
          plan: 'Mensual',
          paymentDate: DateTime(2025, 1, 10),
          receiptUrl: 'https://url.com',
          status: PaymentStatus.rejected,
          rejectionReason: 'Comprobante inválido',
          reviewedBy: 'admin_1',
          reviewedAt: DateTime(2025, 1, 11),
          createdAt: DateTime(2025, 1, 10),
        );

        final map = rejectedPayment.toMap();

        expect(map['status'], 'rejected');
        expect(map['rejectionReason'], 'Comprobante inválido');
        expect(map['reviewedBy'], 'admin_1');
      });
    });

    group('Business Logic', () {
      test('enrollment payment should have correct type', () {
        expect(testPayment.type, PaymentType.enrollment);
      });

      test('monthly payment should have correct type', () {
        final monthlyPayment = Payment(
          userId: 'user_1',
          userName: 'Test User',
          userEmail: 'test@test.com',
          type: PaymentType.monthly,
          amount: 35000.0,
          plan: 'Mensual',
          paymentDate: DateTime(2025, 1, 10),
          receiptUrl: 'https://url.com',
          createdAt: DateTime(2025, 1, 10),
        );

        expect(monthlyPayment.type, PaymentType.monthly);
      });

      test('default status should be pending', () {
        final newPayment = Payment(
          userId: 'user_1',
          userName: 'Test User',
          userEmail: 'test@test.com',
          type: PaymentType.monthly,
          amount: 35000.0,
          plan: 'Mensual',
          paymentDate: DateTime(2025, 1, 10),
          receiptUrl: 'https://url.com',
          createdAt: DateTime(2025, 1, 10),
        );

        expect(newPayment.status, PaymentStatus.pending);
      });

      test('amount should be stored as double', () {
        expect(testPayment.amount, isA<double>());
        expect(testPayment.amount, 50000.0);
      });

      test('should handle different plan types', () {
        final plans = ['Mensual', 'Trimestral', 'Semestral', 'Anual'];

        for (final planName in plans) {
          final payment = Payment(
            userId: 'user_1',
            userName: 'Test',
            userEmail: 'test@test.com',
            type: PaymentType.monthly,
            amount: 35000.0,
            plan: planName,
            paymentDate: DateTime.now(),
            receiptUrl: 'url',
            createdAt: DateTime.now(),
          );

          expect(payment.plan, planName);
        }
      });
    });

    group('Edge Cases', () {
      test('should handle zero amount', () {
        final zeroPayment = Payment(
          userId: 'user_1',
          userName: 'Test',
          userEmail: 'test@test.com',
          type: PaymentType.monthly,
          amount: 0.0,
          plan: 'Mensual',
          paymentDate: DateTime.now(),
          receiptUrl: 'url',
          createdAt: DateTime.now(),
        );

        expect(zeroPayment.amount, 0.0);
        expect(zeroPayment.toMap()['amount'], 0.0);
      });

      test('should handle large amounts', () {
        final largePayment = Payment(
          userId: 'user_1',
          userName: 'Test',
          userEmail: 'test@test.com',
          type: PaymentType.enrollment,
          amount: 999999.99,
          plan: 'Anual',
          paymentDate: DateTime.now(),
          receiptUrl: 'url',
          createdAt: DateTime.now(),
        );

        expect(largePayment.amount, 999999.99);
      });

      test('should handle empty receipt URL gracefully', () {
        final payment = Payment(
          userId: 'user_1',
          userName: 'Test',
          userEmail: 'test@test.com',
          type: PaymentType.monthly,
          amount: 35000.0,
          plan: 'Mensual',
          paymentDate: DateTime.now(),
          receiptUrl: '',
          createdAt: DateTime.now(),
        );

        expect(payment.receiptUrl, '');
        expect(payment.toMap()['receiptUrl'], '');
      });

      test('should handle very long rejection reasons', () {
        final longReason = 'Comprobante inválido ' * 50;
        final rejectedPayment = Payment(
          userId: 'user_1',
          userName: 'Test',
          userEmail: 'test@test.com',
          type: PaymentType.monthly,
          amount: 35000.0,
          plan: 'Mensual',
          paymentDate: DateTime.now(),
          receiptUrl: 'url',
          status: PaymentStatus.rejected,
          rejectionReason: longReason,
          createdAt: DateTime.now(),
        );

        expect(rejectedPayment.rejectionReason, longReason);
      });
    });
  });
}
