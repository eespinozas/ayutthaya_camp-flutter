import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingViewModel extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Crear una reserva
  Future<bool> createBooking(Booking booking) async {
    try {
      _setLoading(true);
      await _bookingService.createBooking(booking);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Obtener número de reservas para una clase
  Future<int> getBookedCount(String scheduleId, DateTime classDate) async {
    try {
      return await _bookingService.getBookedCount(scheduleId, classDate);
    } catch (e) {
      _setError(e.toString());
      return 0;
    }
  }

  /// Obtener reservas de un usuario
  Stream<List<Booking>> getUserBookings(String userId) {
    return _bookingService.getUserBookings(userId);
  }

  /// Obtener reservas futuras de un usuario
  Stream<List<Booking>> getUserUpcomingBookings(String userId) {
    return _bookingService.getUserUpcomingBookings(userId);
  }

  /// Obtener reservas de una clase (admin)
  Stream<List<Booking>> getClassBookings(String scheduleId, DateTime classDate) {
    return _bookingService.getClassBookings(scheduleId, classDate);
  }

  /// Obtener reservas de un día (admin)
  Stream<List<Booking>> getBookingsByDate(DateTime date) {
    return _bookingService.getBookingsByDate(date);
  }

  /// Cancelar una reserva
  Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      _setLoading(true);
      await _bookingService.cancelBooking(bookingId, reason);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Marcar asistencia (admin)
  Future<bool> markAttendance(String bookingId, String adminId) async {
    try {
      _setLoading(true);
      await _bookingService.markAttendance(bookingId, adminId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Marcar no asistencia (admin)
  Future<bool> markNoShow(String bookingId, String adminId) async {
    try {
      _setLoading(true);
      await _bookingService.markNoShow(bookingId, adminId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Confirmar asistencia (usuario)
  Future<bool> confirmAttendance(String bookingId) async {
    try {
      _setLoading(true);
      await _bookingService.confirmAttendance(bookingId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Marcar automáticamente como no asistida si pasó la ventana de confirmación
  Future<void> processExpiredConfirmations() async {
    try {
      await _bookingService.processExpiredConfirmations();
    } catch (e) {
      debugPrint('Error procesando confirmaciones expiradas: $e');
    }
  }

  /// Verificar si tiene reserva
  Future<bool> hasBookingForClass(String userId, String scheduleId, DateTime classDate) async {
    try {
      return await _bookingService.hasBookingForClass(userId, scheduleId, classDate);
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Alias para hasBookingForClass (para compatibilidad)
  Future<bool> hasUserBookedSchedule(String userId, String scheduleId, DateTime classDate) async {
    return hasBookingForClass(userId, scheduleId, classDate);
  }

  /// Obtener estadísticas de asistencia
  Future<Map<String, int>> getUserAttendanceStats(String userId) async {
    try {
      _setLoading(true);
      final stats = await _bookingService.getUserAttendanceStats(userId);
      _setLoading(false);
      return stats;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return {};
    }
  }

  /// Obtener número de clases agendadas por el usuario este mes
  Future<int> getUserBookedClassesThisMonth(String userId, DateTime referenceDate) async {
    try {
      return await _bookingService.getUserBookedClassesThisMonth(userId, referenceDate);
    } catch (e) {
      _setError(e.toString());
      return 0;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
