import 'package:equatable/equatable.dart';

/// Domain Entity for User
/// Pure business logic object with no dependencies
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final bool emailVerified;
  final String? phoneNumber;
  final String? photoUrl;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerified,
    this.phoneNumber,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        emailVerified,
        phoneNumber,
        photoUrl,
        role,
        createdAt,
        updatedAt,
      ];

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is student
  bool get isStudent => role == 'student';

  /// Get display name (first name only)
  String get firstName => name.split(' ').first;

  /// Copy with
  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    bool? emailVerified,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
