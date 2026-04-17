import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/pagination_service.dart';

/// ViewModel para la gestión de alumnos con paginación
class AdminAlumnosViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Servicios de paginación por categoría
  PaginationService<UserSnapshot>? _allStudentsPagination;
  PaginationService<UserSnapshot>? _pendingPagination;
  PaginationService<UserSnapshot>? _activePagination;
  PaginationService<UserSnapshot>? _inactivePagination;

  // Estado
  bool _isInitialized = false;
  String? _errorMessage;
  String _currentFilter = 'all'; // 'all', 'pending', 'active', 'inactive'

  // Getters
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  // Obtener el servicio de paginación actual
  PaginationService<UserSnapshot>? get currentPagination {
    switch (_currentFilter) {
      case 'pending':
        return _pendingPagination;
      case 'active':
        return _activePagination;
      case 'inactive':
        return _inactivePagination;
      default:
        return _allStudentsPagination;
    }
  }

  List<UserSnapshot> get currentUsers => currentPagination?.items ?? [];
  bool get hasMore => currentPagination?.hasMore ?? false;
  bool get isLoading => currentPagination?.isLoading ?? false;

  /// Inicializar el ViewModel
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Servicio para todos los estudiantes (excluyendo admins)
      _allStudentsPagination = PaginationService<UserSnapshot>(
        collectionPath: 'users',
        orderByField: 'createdAt',
        descending: true,
        pageSize: 20,
        fromFirestore: UserSnapshot.fromFirestore,
        queryBuilder: (query) => query.where('role', isNotEqualTo: 'admin'),
      );

      // Servicio para usuarios pendientes
      _pendingPagination = PaginationService<UserSnapshot>(
        collectionPath: 'users',
        orderByField: 'createdAt',
        descending: true,
        pageSize: 20,
        fromFirestore: UserSnapshot.fromFirestore,
        queryBuilder: (query) => query
            .where('role', isNotEqualTo: 'admin')
            .where('membershipStatus', isEqualTo: 'pending'),
      );

      // Servicio para usuarios activos
      _activePagination = PaginationService<UserSnapshot>(
        collectionPath: 'users',
        orderByField: 'createdAt',
        descending: true,
        pageSize: 20,
        fromFirestore: UserSnapshot.fromFirestore,
        queryBuilder: (query) => query
            .where('role', isNotEqualTo: 'admin')
            .where('membershipStatus', isEqualTo: 'active'),
      );

      // Servicio para usuarios inactivos
      _inactivePagination = PaginationService<UserSnapshot>(
        collectionPath: 'users',
        orderByField: 'createdAt',
        descending: true,
        pageSize: 20,
        fromFirestore: UserSnapshot.fromFirestore,
        queryBuilder: (query) => query
            .where('role', isNotEqualTo: 'admin')
            .where('membershipStatus', whereIn: ['none', 'expired', 'frozen']),
      );

      // Cargar la primera página del filtro actual
      await loadFirstPage();

      _isInitialized = true;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al inicializar: $e';
      debugPrint('❌ AdminAlumnosViewModel.initialize error: $e');
      notifyListeners();
    }
  }

  /// Cambiar filtro
  Future<void> setFilter(String filter) async {
    if (_currentFilter == filter) return;

    _currentFilter = filter;
    notifyListeners();

    // Cargar datos si el servicio no tiene items
    if (currentPagination?.isEmpty ?? true) {
      await loadFirstPage();
    }
  }

  /// Cargar la primera página
  Future<void> loadFirstPage() async {
    try {
      await currentPagination?.loadFirstPage();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar datos: $e';
      debugPrint('❌ AdminAlumnosViewModel.loadFirstPage error: $e');
      notifyListeners();
    }
  }

  /// Cargar la siguiente página
  Future<void> loadNextPage() async {
    if (!hasMore || isLoading) return;

    try {
      await currentPagination?.loadNextPage();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar más datos: $e';
      debugPrint('❌ AdminAlumnosViewModel.loadNextPage error: $e');
      notifyListeners();
    }
  }

  /// Refrescar los datos actuales
  Future<void> refresh() async {
    try {
      await currentPagination?.refresh();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al refrescar: $e';
      debugPrint('❌ AdminAlumnosViewModel.refresh error: $e');
      notifyListeners();
    }
  }

  /// Obtener conteos rápidos (sin paginación) para los badges
  Future<Map<String, int>> getQuickCounts() async {
    try {
      final allSnapshot = await _firestore
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .count()
          .get();

      final pendingSnapshot = await _firestore
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .where('membershipStatus', isEqualTo: 'pending')
          .count()
          .get();

      final activeSnapshot = await _firestore
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .where('membershipStatus', isEqualTo: 'active')
          .count()
          .get();

      return {
        'all': allSnapshot.count ?? 0,
        'pending': pendingSnapshot.count ?? 0,
        'active': activeSnapshot.count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting counts: $e');
      return {'all': 0, 'pending': 0, 'active': 0};
    }
  }

  @override
  void dispose() {
    _allStudentsPagination?.clear();
    _pendingPagination?.clear();
    _activePagination?.clear();
    _inactivePagination?.clear();
    super.dispose();
  }
}
