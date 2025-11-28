import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/plan.dart';

class PlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Nombre de la colección de escuelas
  static const String schoolsCollection = 'schools';
  // ID de tu escuela
  static const String schoolId = 'ayutthaya-camp';

  /// Obtener todos los planes activos desde la subcollección
  Stream<List<Plan>> getActivePlans() {
    debugPrint('=== PlanService.getActivePlans ===');
    debugPrint('Ruta completa: $schoolsCollection/$schoolId/planes');

    return _firestore
        .collection(schoolsCollection)
        .doc(schoolId)
        .collection('planes')
        .snapshots()
        .map((snapshot) {
      debugPrint('Total documentos en "planes": ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        debugPrint('❌ NO HAY DOCUMENTOS en la subcollección "planes"');
        debugPrint('Verifica en Firebase Console que exista:');
        debugPrint('  - Colección: $schoolsCollection');
        debugPrint('  - Documento: $schoolId');
        debugPrint('  - Subcolección: planes');
        return <Plan>[];
      }

      final allPlans = snapshot.docs.map((doc) {
        debugPrint('---');
        debugPrint('Documento ID: ${doc.id}');
        debugPrint('Datos completos: ${doc.data()}');

        try {
          final plan = Plan.fromFirestore(doc);
          debugPrint('✅ Plan parseado: ${plan.name} - \$${plan.price} - active: ${plan.active}');
          return plan;
        } catch (e) {
          debugPrint('❌ ERROR al parsear plan: $e');
          rethrow;
        }
      }).toList();

      // Filtrar solo los activos
      final activePlans = allPlans.where((plan) => plan.active).toList();
      debugPrint('Planes activos: ${activePlans.length} de ${allPlans.length}');

      // Ordenar por displayOrder
      activePlans.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      for (var plan in activePlans) {
        debugPrint('  ✓ ${plan.name} (\$${plan.price}) - order: ${plan.displayOrder}');
      }

      return activePlans;
    }).handleError((error, stackTrace) {
      debugPrint('❌ ERROR STREAM en getActivePlans: $error');
      debugPrint('StackTrace: $stackTrace');
      throw error;
    });
  }

  /// Obtener todos los planes (admin)
  Stream<List<Plan>> getAllPlans() {
    return _firestore
        .collection(schoolsCollection)
        .doc(schoolId)
        .collection('planes')
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Plan.fromFirestore(doc)).toList();
    });
  }

  /// Obtener un plan por ID
  Future<Plan?> getPlanById(String planId) async {
    try {
      final doc = await _firestore
          .collection(schoolsCollection)
          .doc(schoolId)
          .collection('planes')
          .doc(planId)
          .get();
      if (doc.exists) {
        return Plan.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener plan: $e');
    }
  }

  /// Crear un plan (admin)
  Future<String> createPlan(Plan plan) async {
    try {
      final docRef = await _firestore
          .collection(schoolsCollection)
          .doc(schoolId)
          .collection('planes')
          .add(plan.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear plan: $e');
    }
  }

  /// Actualizar un plan (admin)
  Future<void> updatePlan(String planId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(schoolsCollection)
          .doc(schoolId)
          .collection('planes')
          .doc(planId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar plan: $e');
    }
  }

  /// Eliminar un plan (admin) - soft delete
  Future<void> deletePlan(String planId) async {
    try {
      await _firestore
          .collection(schoolsCollection)
          .doc(schoolId)
          .collection('planes')
          .doc(planId)
          .update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al eliminar plan: $e');
    }
  }

  /// Obtener el precio de matrícula de la escuela
  Future<double> getRegistrationPrice() async {
    try {
      debugPrint('PlanService.getRegistrationPrice - collection: $schoolsCollection, schoolId: $schoolId');

      final doc = await _firestore.collection(schoolsCollection).doc(schoolId).get();

      if (!doc.exists) {
        debugPrint('ERROR: Documento de escuela no existe');
        throw Exception('Escuela no encontrada');
      }

      final data = doc.data();
      debugPrint('Datos de escuela: $data');

      if (data == null || !data.containsKey('registrationPrice')) {
        debugPrint('ERROR: Campo registrationPrice no existe');
        throw Exception('Precio de matrícula no configurado');
      }

      final price = (data['registrationPrice'] as num).toDouble();
      debugPrint('Precio de matrícula: \$$price');

      return price;
    } catch (e) {
      debugPrint('ERROR en getRegistrationPrice: $e');
      throw Exception('Error al obtener precio de matrícula: $e');
    }
  }
}
