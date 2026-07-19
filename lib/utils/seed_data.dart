import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilidad para poblar la base de datos con datos iniciales
class SeedData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Agregar planes iniciales a Firestore
  static Future<void> seedPlans() async {
    debugPrint('🔥 Iniciando seed de planes...');

    final plans = [
      {
        'name': 'Plan Novato',
        'price': 10000.0,
        'durationDays': 30,
        'description': '1 clase mensual - Ideal para probar',
        'active': true,
        'displayOrder': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'name': 'Plan Iniciado',
        'price': 35000.0,
        'durationDays': 30,
        'description': '4 clases mensuales - Para empezar tu entrenamiento',
        'active': true,
        'displayOrder': 2,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'name': 'Plan Guerrero',
        'price': 45000.0,
        'durationDays': 30,
        'description': '8 clases mensuales - Entrena de forma regular',
        'active': true,
        'displayOrder': 3,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'name': 'Plan Nak Muay',
        'price': 55000.0,
        'durationDays': 30,
        'description': '12 clases mensuales - Mejora tu técnica',
        'active': true,
        'displayOrder': 4,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'name': 'Plan Peleador',
        'price': 65000.0,
        'durationDays': 30,
        'description': 'Clases ilimitadas - Entrena todos los días',
        'active': true,
        'displayOrder': 5,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
    ];

    int count = 0;
    for (var plan in plans) {
      try {
        final docRef = await _firestore.collection('plans').add(plan);
        count++;
        debugPrint('✅ Plan agregado: "${plan['name']}" con ID: ${docRef.id}');
      } catch (e) {
        debugPrint('❌ Error al agregar "${plan['name']}": $e');
      }
    }

    debugPrint('🎉 Seed completado! Se agregaron $count planes.');
  }

  /// Agregar horarios de clases iniciales a Firestore
  static Future<void> seedClassSchedules() async {
    debugPrint('🔥 Iniciando seed de horarios de clases...');

    final schedules = [
      // LUNES, MIÉRCOLES, VIERNES (días 1, 3, 5)
      {
        'time': '07:00',
        'instructor': 'Francisco Poveda',
        'type': 'Muay Thai',
        'capacity': 15,
        'daysOfWeek': [1, 3, 5],
        'active': true,
        'displayOrder': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'time': '08:00',
        'instructor': 'Francisco Poveda',
        'type': 'Boxing',
        'capacity': 15,
        'daysOfWeek': [1, 3, 5],
        'active': true,
        'displayOrder': 2,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'time': '09:30',
        'instructor': 'Carlos Mendoza',
        'type': 'Muay Thai',
        'capacity': 15,
        'daysOfWeek': [1, 3, 5],
        'active': true,
        'displayOrder': 3,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'time': '18:00',
        'instructor': 'Francisco Poveda',
        'type': 'Muay Thai',
        'capacity': 15,
        'daysOfWeek': [1, 3, 5],
        'active': true,
        'displayOrder': 4,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'time': '20:00',
        'instructor': 'Carlos Mendoza',
        'type': 'Boxing',
        'capacity': 15,
        'daysOfWeek': [1, 3, 5],
        'active': true,
        'displayOrder': 5,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },

      // MARTES Y JUEVES (días 2, 4)
      {
        'time': '07:00',
        'instructor': 'Francisco Poveda',
        'type': 'Muay Thai',
        'capacity': 15,
        'daysOfWeek': [2, 4],
        'active': true,
        'displayOrder': 6,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'time': '08:00',
        'instructor': 'Francisco Poveda',
        'type': 'Boxing',
        'capacity': 15,
        'daysOfWeek': [2, 4],
        'active': true,
        'displayOrder': 7,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'time': '09:30',
        'instructor': 'Carlos Mendoza',
        'type': 'Muay Thai',
        'capacity': 15,
        'daysOfWeek': [2, 4],
        'active': true,
        'displayOrder': 8,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'time': '18:30',
        'instructor': 'Francisco Poveda',
        'type': 'Muay Thai',
        'capacity': 15,
        'daysOfWeek': [2, 4],
        'active': true,
        'displayOrder': 9,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'time': '20:00',
        'instructor': 'Carlos Mendoza',
        'type': 'Boxing',
        'capacity': 15,
        'daysOfWeek': [2, 4],
        'active': true,
        'displayOrder': 10,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },

      // SÁBADO (día 6)
      {
        'time': '11:00',
        'instructor': 'Francisco Poveda',
        'type': 'Muay Thai',
        'capacity': 20,
        'daysOfWeek': [6],
        'active': true,
        'displayOrder': 11,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
      {
        'time': '13:00',
        'instructor': 'Carlos Mendoza',
        'type': 'Muay Thai',
        'capacity': 20,
        'daysOfWeek': [6],
        'active': true,
        'displayOrder': 12,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      },
    ];

    int count = 0;
    for (var schedule in schedules) {
      try {
        final docRef = await _firestore
            .collection('class_schedules')
            .add(schedule);
        count++;
        debugPrint(
          '✅ Horario agregado: "${schedule['type']}" a las ${schedule['time']} con ID: ${docRef.id}',
        );
      } catch (e) {
        debugPrint('❌ Error al agregar horario "${schedule['type']}": $e');
      }
    }

    debugPrint('🎉 Seed completado! Se agregaron $count horarios.');
  }

  /// Ejecutar todos los seeds
  static Future<void> seedAll() async {
    await seedPlans();
    debugPrint('\n');
    await seedClassSchedules();
  }
}
