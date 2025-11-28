import 'package:flutter/foundation.dart';
import '../models/class_schedule.dart';
import '../services/class_schedule_service.dart';

class ClassScheduleViewModel extends ChangeNotifier {
  final ClassScheduleService _scheduleService = ClassScheduleService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtener todos los horarios activos
  Stream<List<ClassSchedule>> getActiveSchedules() {
    return _scheduleService.getActiveSchedules();
  }

  /// Obtener horarios para un día específico
  Stream<List<ClassSchedule>> getSchedulesForDay(int dayOfWeek) {
    return _scheduleService.getSchedulesForDay(dayOfWeek);
  }

  /// Obtener todos los horarios (admin)
  Stream<List<ClassSchedule>> getAllSchedules() {
    return _scheduleService.getAllSchedules();
  }

  /// Obtener horarios agrupados por hora
  Future<Map<String, List<ClassSchedule>>> getSchedulesGroupedByTime() async {
    try {
      _setLoading(true);
      final grouped = await _scheduleService.getSchedulesGroupedByTime();
      _setLoading(false);
      return grouped;
    } catch (e) {
      _setError('Error al obtener horarios: $e');
      _setLoading(false);
      return {};
    }
  }

  /// Obtener un horario por ID
  Future<ClassSchedule?> getScheduleById(String scheduleId) async {
    try {
      _setLoading(true);
      final schedule = await _scheduleService.getScheduleById(scheduleId);
      _setLoading(false);
      return schedule;
    } catch (e) {
      _setError('Error al obtener horario: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Crear un horario (admin)
  Future<bool> createSchedule(ClassSchedule schedule) async {
    try {
      _setLoading(true);
      await _scheduleService.createSchedule(schedule);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear horario: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Actualizar un horario (admin)
  Future<bool> updateSchedule(String scheduleId, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      await _scheduleService.updateSchedule(scheduleId, data);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al actualizar horario: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Eliminar un horario (admin)
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      _setLoading(true);
      await _scheduleService.deleteSchedule(scheduleId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al eliminar horario: $e');
      _setLoading(false);
      return false;
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
