// ViewModel (Presentation Layer)
// Manages UI state and business logic for {{FeatureName}} feature
// Uses Provider pattern (ChangeNotifier)

import 'package:flutter/foundation.dart';
import '../../domain/entities/{{feature_name}}.dart';
import '../../domain/repositories/{{feature_name}}_repository.dart';

class {{FeatureName}}ViewModel extends ChangeNotifier {
  final {{FeatureName}}Repository _repository;

  {{FeatureName}}ViewModel(this._repository);

  // State
  List<{{FeatureName}}> _{{feature_name}}s = [];
  bool _isLoading = false;
  String? _error;
  {{FeatureName}}? _selected{{FeatureName}};

  // Getters
  List<{{FeatureName}}> get {{feature_name}}s => _{{feature_name}}s;
  bool get isLoading => _isLoading;
  String? get error => _error;
  {{FeatureName}}? get selected{{FeatureName}} => _selected{{FeatureName}};
  bool get hasError => _error != null;
  bool get isEmpty => _{{feature_name}}s.isEmpty && !_isLoading;

  // Load all {{feature_name}}s for a user
  Future<void> loadAll(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _{{feature_name}}s = await _repository.getAll{{FeatureName}}s(userId);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar {{feature_name}}s: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load a single {{feature_name}} by ID
  Future<void> loadById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      _selected{{FeatureName}} = await _repository.get{{FeatureName}}ById(id);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar {{feature_name}}: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Create new {{feature_name}}
  Future<bool> create({{FeatureName}} {{feature_name}}) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.create{{FeatureName}}({{feature_name}});
      _{{feature_name}}s.insert(0, {{feature_name}});
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear {{feature_name}}: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing {{feature_name}}
  Future<bool> update({{FeatureName}} {{feature_name}}) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.update{{FeatureName}}({{feature_name}});

      final index = _{{feature_name}}s.indexWhere((n) => n.id == {{feature_name}}.id);
      if (index != -1) {
        _{{feature_name}}s[index] = {{feature_name}};
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar {{feature_name}}: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete {{feature_name}}
  Future<bool> delete(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.delete{{FeatureName}}(id);
      _{{feature_name}}s.removeWhere((n) => n.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar {{feature_name}}: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Watch real-time updates
  void watchAll(String userId) {
    _repository.watch{{FeatureName}}s(userId).listen(
      ({{feature_name}}s) {
        _{{feature_name}}s = {{feature_name}}s;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error watching {{feature_name}}s: $error');
      },
    );
  }

  // Select a {{feature_name}}
  void select({{FeatureName}} {{feature_name}}) {
    _selected{{FeatureName}} = {{feature_name}};
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selected{{FeatureName}} = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Private helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
