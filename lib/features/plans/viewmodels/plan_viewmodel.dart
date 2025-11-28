import 'package:flutter/foundation.dart';
import '../models/plan.dart';
import '../services/plan_service.dart';

class PlanViewModel extends ChangeNotifier {
  final PlanService _planService = PlanService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtener todos los planes activos
  Stream<List<Plan>> getActivePlans() {
    return _planService.getActivePlans();
  }

  /// Obtener todos los planes (admin)
  Stream<List<Plan>> getAllPlans() {
    return _planService.getAllPlans();
  }

  /// Obtener un plan por ID
  Future<Plan?> getPlanById(String planId) async {
    try {
      _setLoading(true);
      final plan = await _planService.getPlanById(planId);
      _setLoading(false);
      return plan;
    } catch (e) {
      _setError('Error al obtener plan: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Crear un plan (admin)
  Future<bool> createPlan(Plan plan) async {
    try {
      _setLoading(true);
      await _planService.createPlan(plan);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear plan: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Actualizar un plan (admin)
  Future<bool> updatePlan(String planId, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      await _planService.updatePlan(planId, data);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al actualizar plan: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Eliminar un plan (admin)
  Future<bool> deletePlan(String planId) async {
    try {
      _setLoading(true);
      await _planService.deletePlan(planId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al eliminar plan: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Obtener precio de matrícula
  Future<double?> getRegistrationPrice() async {
    try {
      return await _planService.getRegistrationPrice();
    } catch (e) {
      _setError('Error al obtener precio de matrícula: $e');
      return null;
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
