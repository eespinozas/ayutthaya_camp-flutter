// Repository Interface (Domain Layer)
// Defines the contract for data operations, agnostic of implementation

import '../entities/{{feature_name}}.dart';

abstract class {{FeatureName}}Repository {
  /// Fetch all {{feature_name}}s for a user
  Future<List<{{FeatureName}}>> getAll{{FeatureName}}s(String userId);

  /// Fetch a single {{feature_name}} by ID
  Future<{{FeatureName}}?> get{{FeatureName}}ById(String id);

  /// Create a new {{feature_name}}
  Future<void> create{{FeatureName}}({{FeatureName}} {{feature_name}});

  /// Update an existing {{feature_name}}
  Future<void> update{{FeatureName}}({{FeatureName}} {{feature_name}});

  /// Delete a {{feature_name}}
  Future<void> delete{{FeatureName}}(String id);

  /// Stream of {{feature_name}}s (for real-time updates)
  Stream<List<{{FeatureName}}>> watch{{FeatureName}}s(String userId);
}
