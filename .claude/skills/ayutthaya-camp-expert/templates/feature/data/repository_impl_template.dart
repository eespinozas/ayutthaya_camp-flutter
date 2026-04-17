// Repository Implementation (Data Layer)
// Implements the domain repository interface using Firebase/API

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/{{feature_name}}.dart';
import '../../domain/repositories/{{feature_name}}_repository.dart';
import '../dto/{{feature_name}}_dto.dart';

class {{FeatureName}}RepositoryImpl implements {{FeatureName}}Repository {
  final FirebaseFirestore _firestore;
  final String _collectionName = '{{feature_name}}s'; // TODO: Verify collection name

  {{FeatureName}}RepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<{{FeatureName}}>> getAll{{FeatureName}}s(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {{FeatureName}}DTO.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch {{feature_name}}s: $e');
    }
  }

  @override
  Future<{{FeatureName}}?> get{{FeatureName}}ById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();

      if (!doc.exists) return null;

      return {{FeatureName}}DTO.fromFirestore(doc).toEntity();
    } catch (e) {
      throw Exception('Failed to fetch {{feature_name}}: $e');
    }
  }

  @override
  Future<void> create{{FeatureName}}({{FeatureName}} {{feature_name}}) async {
    try {
      final dto = {{FeatureName}}DTO.fromEntity({{feature_name}});
      await _firestore.collection(_collectionName).doc({{feature_name}}.id).set(dto.toFirestore());
    } catch (e) {
      throw Exception('Failed to create {{feature_name}}: $e');
    }
  }

  @override
  Future<void> update{{FeatureName}}({{FeatureName}} {{feature_name}}) async {
    try {
      final dto = {{FeatureName}}DTO.fromEntity({{feature_name}});
      await _firestore
          .collection(_collectionName)
          .doc({{feature_name}}.id)
          .update(dto.toFirestore());
    } catch (e) {
      throw Exception('Failed to update {{feature_name}}: $e');
    }
  }

  @override
  Future<void> delete{{FeatureName}}(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete {{feature_name}}: $e');
    }
  }

  @override
  Stream<List<{{FeatureName}}>> watch{{FeatureName}}s(String userId) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {{FeatureName}}DTO.fromFirestore(doc).toEntity())
              .toList());
    } catch (e) {
      throw Exception('Failed to watch {{feature_name}}s: $e');
    }
  }
}
