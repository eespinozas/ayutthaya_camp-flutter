import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_entity.dart';
import 'dashboard_dto.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Future<DashboardEntity> fetch() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No hay usuario autenticado');

    final doc = await _db.collection('dashboards').doc(uid).get();
    if (!doc.exists) {
      // Si no existe, devuelve valores por defecto
      return DashboardEntity.empty();
    }
    final data = doc.data()!;
    return DashboardDto.fromJson(data).toEntity();
  }
}
