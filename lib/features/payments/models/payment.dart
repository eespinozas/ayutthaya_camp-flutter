import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType {
  enrollment, // Matrícula
  monthly, // Mensualidad
}

enum PaymentStatus {
  pending, // Pendiente de aprobación
  approved, // Aprobado
  rejected, // Rechazado
  failed, // Fallido (error al procesar)
}

class Payment {
  final String? id;
  final String userId;
  final String userName;
  final String userEmail;
  final PaymentType type;
  final double amount;
  final String plan;
  // Para pagos de matrícula: nombre del plan mensual elegido al momento de
  // pagar la matrícula. Al aprobar la matrícula se usa para asignar el plan
  // al user doc (planName, classesPerMonth, durationDays) y arrancar la
  // mensualidad junto con la matrícula. Null para pagos mensuales o
  // matrículas viejas creadas antes de este campo.
  final String? enrollmentPlan;
  final DateTime paymentDate;
  final String receiptUrl;
  final PaymentStatus status;
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.amount,
    required this.plan,
    this.enrollmentPlan,
    required this.paymentDate,
    required this.receiptUrl,
    this.status = PaymentStatus.pending,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'type': type.name,
      'amount': amount,
      'plan': plan,
      'enrollmentPlan': enrollmentPlan,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'receiptUrl': receiptUrl,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore document
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Payment(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      type: PaymentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PaymentType.monthly,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      plan: data['plan'] ?? 'Mensual',
      enrollmentPlan: data['enrollmentPlan'] as String?,
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      receiptUrl: data['receiptUrl'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      rejectionReason: data['rejectionReason'],
      reviewedBy: data['reviewedBy'],
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
