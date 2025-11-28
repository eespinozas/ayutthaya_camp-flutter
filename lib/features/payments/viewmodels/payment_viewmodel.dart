import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

class PaymentViewModel extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Crear pago con comprobante
  Future<bool> createPayment({
    required String userId,
    required String userName,
    required String userEmail,
    required PaymentType type,
    required double amount,
    required String plan,
    required DateTime paymentDate,
    File? receiptFile,
    Uint8List? receiptBytes,
    String? receiptFileName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createPayment(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        type: type,
        amount: amount,
        plan: plan,
        paymentDate: paymentDate,
        receiptFile: receiptFile,
        receiptBytes: receiptBytes,
        receiptFileName: receiptFileName,
      );

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtener pagos del usuario
  Stream<List<Payment>> getUserPayments(String userId) {
    return _service.getUserPayments(userId);
  }

  /// Obtener todos los pagos (admin)
  Stream<List<Payment>> getAllPayments() {
    return _service.getAllPayments();
  }

  /// Obtener pagos por estado (admin)
  Stream<List<Payment>> getPaymentsByStatus(PaymentStatus status) {
    return _service.getPaymentsByStatus(status);
  }

  /// Aprobar pago (admin)
  Future<bool> approvePayment(String paymentId, String adminId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.approvePayment(paymentId, adminId);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Rechazar pago (admin)
  Future<bool> rejectPayment(String paymentId, String adminId, String reason) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.rejectPayment(paymentId, adminId, reason);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verificar si tiene matrícula aprobada
  Future<bool> hasApprovedEnrollment(String userId) async {
    try {
      return await _service.hasApprovedEnrollment(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
