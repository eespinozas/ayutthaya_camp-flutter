import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio genérico de paginación para Firestore
///
/// Uso:
/// ```dart
/// final paginationService = PaginationService<UserModel>(
///   collectionPath: 'users',
///   orderByField: 'createdAt',
///   descending: true,
///   pageSize: 20,
///   fromFirestore: (doc) => UserModel.fromFirestore(doc),
/// );
///
/// await paginationService.loadNextPage();
/// ```
class PaginationService<T> {
  final String collectionPath;
  final String orderByField;
  final bool descending;
  final int pageSize;
  final T Function(DocumentSnapshot) fromFirestore;
  final Query Function(Query)? queryBuilder;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estado de paginación
  final List<T> _items = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;

  PaginationService({
    required this.collectionPath,
    required this.orderByField,
    this.descending = false,
    this.pageSize = 20,
    required this.fromFirestore,
    this.queryBuilder,
  });

  List<T> get items => List.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;

  /// Cargar la primera página (reset)
  Future<void> loadFirstPage() async {
    _items.clear();
    _lastDocument = null;
    _hasMore = true;
    await loadNextPage();
  }

  /// Cargar la siguiente página
  Future<void> loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;

    try {
      Query query = _firestore.collection(collectionPath);

      // Aplicar query builder personalizado (para WHERE clauses)
      if (queryBuilder != null) {
        query = queryBuilder!(query);
      }

      // Ordenar
      query = query.orderBy(orderByField, descending: descending);

      // Paginación
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = snapshot.docs.last;

        final newItems = snapshot.docs.map((doc) => fromFirestore(doc)).toList();
        _items.addAll(newItems);

        // Si recibimos menos documentos que el pageSize, no hay más
        if (snapshot.docs.length < pageSize) {
          _hasMore = false;
        }
      }

      debugPrint('📄 Pagination: Loaded ${snapshot.docs.length} items (Total: ${_items.length})');
    } catch (e) {
      debugPrint('❌ Error loading page: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Refrescar todos los datos (útil después de cambios)
  Future<void> refresh() async {
    await loadFirstPage();
  }

  /// Limpiar el estado
  void clear() {
    _items.clear();
    _lastDocument = null;
    _hasMore = true;
    _isLoading = false;
  }
}

/// Modelo simple para usuarios (para usar en el servicio de paginación)
class UserSnapshot {
  final String id;
  final String email;
  final String name;
  final String role;
  final String membershipStatus;
  final DateTime? createdAt;
  final DateTime? membershipExpirationDate;

  UserSnapshot({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.membershipStatus,
    this.createdAt,
    this.membershipExpirationDate,
  });

  factory UserSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSnapshot(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      membershipStatus: data['membershipStatus'] ?? 'none',
      createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null,
      membershipExpirationDate: data['membershipExpirationDate'] != null
        ? (data['membershipExpirationDate'] as Timestamp).toDate()
        : null,
    );
  }
}
