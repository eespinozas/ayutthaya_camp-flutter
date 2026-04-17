// Domain Entity: {{FeatureName}}
// This is the core business object, free from external dependencies

class {{FeatureName}} {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // TODO: Add your business fields here

  {{FeatureName}}({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  {{FeatureName}} copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {{FeatureName}}(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return '{{FeatureName}}(id: $id, userId: $userId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is {{FeatureName}} &&
        other.id == id &&
        other.userId == userId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
