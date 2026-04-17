// Data Transfer Object (DTO)
// Handles serialization/deserialization between API/Firebase and domain entities

import '../../domain/entities/{{feature_name}}.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class {{FeatureName}}DTO {
  final String id;
  final String userId;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  // TODO: Add corresponding fields from entity

  {{FeatureName}}DTO({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  // From Firestore document
  factory {{FeatureName}}DTO.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {{FeatureName}}DTO(
      id: doc.id,
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
    );
  }

  // To Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // From JSON (if using HTTP API)
  factory {{FeatureName}}DTO.fromJson(Map<String, dynamic> json) {
    return {{FeatureName}}DTO(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: Timestamp.fromDate(DateTime.parse(json['createdAt'])),
      updatedAt: json['updatedAt'] != null
          ? Timestamp.fromDate(DateTime.parse(json['updatedAt']))
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toDate().toIso8601String(),
      'updatedAt': updatedAt?.toDate().toIso8601String(),
    };
  }

  // Convert DTO to Domain Entity
  {{FeatureName}} toEntity() {
    return {{FeatureName}}(
      id: id,
      userId: userId,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  // Convert Domain Entity to DTO
  factory {{FeatureName}}DTO.fromEntity({{FeatureName}} entity) {
    return {{FeatureName}}DTO(
      id: entity.id,
      userId: entity.userId,
      createdAt: Timestamp.fromDate(entity.createdAt),
      updatedAt: entity.updatedAt != null
          ? Timestamp.fromDate(entity.updatedAt!)
          : null,
    );
  }
}
