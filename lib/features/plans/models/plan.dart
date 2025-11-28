import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  final String? id;
  final String name; // "Mensual", "Trimestral", etc.
  final double price; // Precio en CLP
  final int durationDays; // Duración en días (30, 90, 180, 365)
  final String description;
  final int? classesPerMonth; // Número de clases permitidas por mes (null = ilimitado)
  final bool active; // Si el plan está activo o no
  final int displayOrder; // Orden de visualización
  final DateTime createdAt;
  final DateTime? updatedAt;

  Plan({
    this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.description,
    this.classesPerMonth,
    this.active = true,
    this.displayOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Verifica si el plan es ilimitado
  bool get isUnlimited => classesPerMonth == null;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'priceCLP': price,
      'durationDays': durationDays,
      'description': description,
      'classesPerMonth': classesPerMonth,
      'active': active,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory Plan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Plan(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['priceCLP'] ?? 0).toDouble(),
      durationDays: data['durationDays'] ?? 30,
      description: data['description'] ?? '',
      classesPerMonth: data['classesPerMonth'],
      active: data['active'] ?? true,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
