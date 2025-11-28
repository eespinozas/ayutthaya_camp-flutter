import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script para poblar la colección 'plans' en Firestore
/// Ejecutar con: flutter run scripts/seed_plans.dart

Future<void> main() async {
  print('🔥 Iniciando seed de planes...');

  // Inicializar Firebase
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final plansCollection = firestore.collection('plans');

  // Definir los planes
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

  print('\n📦 Agregando ${plans.length} planes a Firestore...\n');

  // Agregar cada plan
  int count = 0;
  for (var plan in plans) {
    try {
      final docRef = await plansCollection.add(plan);
      count++;
      print('✅ Plan ${count}/${plans.length}: "${plan['name']}" agregado con ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error al agregar "${plan['name']}": $e');
    }
  }

  print('\n🎉 Seed completado! Se agregaron $count planes.\n');
  print('Puedes verificarlos en Firebase Console:');
  print('https://console.firebase.google.com/project/YOUR_PROJECT/firestore/data/plans');

  // Cerrar la app
  print('\n✋ Presiona Ctrl+C para salir.');
}
