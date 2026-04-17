# Ayutthaya Camp Architecture

## Overview

The project follows **Clean Architecture** with strict layer separation.

## Layer Structure

```
lib/
├── app/                    # App initialization
│   ├── app.dart           # Main app with MultiProvider
│   └── theme.dart         # Theme configuration
├── core/                   # Shared utilities
│   ├── api_client.dart    # HTTP client wrapper
│   ├── config.dart        # Environment config
│   ├── services/          # Shared services
│   └── widgets/           # Reusable widgets
├── features/              # Feature modules (Clean Architecture)
│   └── {feature_name}/
│       ├── data/          # Data layer
│       ├── domain/        # Business logic
│       └── presentation/  # UI layer
└── main.dart              # Entry point
```

## Feature Module Structure

Each feature follows Clean Architecture:

### Domain Layer (Business Logic)

```
domain/
├── entities/              # Business objects (pure Dart classes)
│   └── {entity}.dart     # e.g., User, Payment, Booking
└── repositories/          # Repository interfaces (contracts)
    └── {entity}_repository.dart
```

**Rules:**
- No Flutter dependencies
- No Firebase dependencies
- Pure Dart classes
- Immutable entities

### Data Layer (External Dependencies)

```
data/
├── dto/                   # Data Transfer Objects
│   └── {entity}_dto.dart # Handles serialization/deserialization
├── api/                   # API clients (optional)
│   └── {entity}_api.dart
└── repositories/          # Repository implementations
    └── {entity}_repository_impl.dart
```

**Rules:**
- Implements domain repository interfaces
- Uses Firebase, HTTP, local storage
- Converts DTOs ↔ Entities
- Handles errors and transforms them

### Presentation Layer (UI)

```
presentation/
├── pages/                 # Full screens
│   └── {feature}_page.dart
├── viewmodels/            # State management (Provider)
│   └── {feature}_viewmodel.dart
└── widgets/               # Feature-specific widgets
    └── {widget}_widget.dart
```

**Rules:**
- Uses Provider for state management
- ViewModels extend `ChangeNotifier`
- Pages are `StatefulWidget` or `StatelessWidget`
- Consumes ViewModels via `Provider.of` or `Consumer`

## State Management (Provider Pattern)

### ViewModel Template

```dart
class FeatureViewModel extends ChangeNotifier {
  final FeatureRepository _repository;

  FeatureViewModel(this._repository);

  // State
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Methods
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getItems();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Registration in app.dart

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(AuthRepositoryImpl()),
    ),
    ChangeNotifierProvider(
      create: (_) => FeatureViewModel(FeatureRepositoryImpl()),
    ),
  ],
  child: MaterialApp(...),
)
```

## Firebase Integration

### Firestore Access

All Firestore operations go through repositories:

```dart
class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Booking>> getBookings(String userId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => BookingDTO.fromFirestore(doc).toEntity())
        .toList();
  }
}
```

### Firestore Rules Pattern

```javascript
match /collection/{docId} {
  // User can read own documents
  allow read: if request.auth.uid == resource.data.userId;

  // Admin can read all
  allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';

  // User can create own documents
  allow create: if request.auth.uid == request.resource.data.userId;
}
```

## Navigation

### Routes

Defined in `lib/app/app.dart`:

```dart
MaterialApp(
  routes: {
    '/': (context) => const ShellPage(),
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),
    '/dashboard': (context) => const DashboardPage(),
  },
)
```

### Bottom Navigation (ShellPage)

Main app uses bottom navigation with 5 tabs:
1. Inicio (Dashboard)
2. Agendar (Schedule)
3. Mis Clases (My Classes)
4. Pagos (Payments)
5. Mi Perfil (Profile)

## Data Flow

```
User Action
   ↓
Widget (onPressed)
   ↓
ViewModel (method call)
   ↓
Repository Interface
   ↓
Repository Implementation
   ↓
Firestore / API
   ↓
DTO (deserialization)
   ↓
Entity (business object)
   ↓
ViewModel (update state)
   ↓
notifyListeners()
   ↓
Consumer rebuilds
   ↓
UI updates
```

## Error Handling

### In Repositories

```dart
try {
  final snapshot = await _firestore.collection('users').doc(id).get();
  return UserDTO.fromFirestore(snapshot).toEntity();
} catch (e) {
  throw Exception('Failed to fetch user: $e');
}
```

### In ViewModels

```dart
try {
  _items = await _repository.getItems();
  _error = null;
} catch (e) {
  _error = 'Error loading items: ${e.toString()}';
}
notifyListeners();
```

### In UI

```dart
Consumer<FeatureViewModel>(
  builder: (context, viewModel, child) {
    if (viewModel.hasError) {
      return ErrorMessage(message: viewModel.error!);
    }
    // ... rest of UI
  },
)
```

## Testing Strategy

### Unit Tests (ViewModels)

```dart
test('loadItems sets loading state', () async {
  final mockRepo = MockFeatureRepository();
  final viewModel = FeatureViewModel(mockRepo);

  when(mockRepo.getItems()).thenAnswer((_) async => []);

  await viewModel.loadItems();

  expect(viewModel.isLoading, false);
  expect(viewModel.items, isEmpty);
});
```

### Widget Tests (Pages)

```dart
testWidgets('shows loading indicator', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: FeaturePage(),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## Best Practices

1. **Never access Firebase directly from UI**
   - Always use repositories

2. **Keep entities pure**
   - No Flutter/Firebase imports in domain layer

3. **Use DTOs for serialization**
   - Separate data format from business logic

4. **ViewModels handle all business logic**
   - Pages should be thin, just UI

5. **Always call notifyListeners()**
   - After state changes in ViewModels

6. **Use const constructors**
   - For performance (widgets)

7. **Dispose properly**
   - Override dispose() in ViewModels if needed

## Common Patterns

### Loading State Pattern

```dart
if (viewModel.isLoading) {
  return CircularProgressIndicator();
}

if (viewModel.hasError) {
  return ErrorMessage(message: viewModel.error!);
}

if (viewModel.isEmpty) {
  return EmptyState();
}

return DataView(data: viewModel.items);
```

### Form Handling Pattern

```dart
final _formKey = GlobalKey<FormState>();

void _submit() {
  if (_formKey.currentState!.validate()) {
    final viewModel = context.read<FeatureViewModel>();
    viewModel.createItem(item);
  }
}
```

### Confirmation Dialog Pattern

```dart
final confirm = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Confirm'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('Confirm'),
      ),
    ],
  ),
);

if (confirm == true) {
  // Proceed with action
}
```

## File Naming Conventions

- **Files:** snake_case (e.g., `user_repository.dart`)
- **Classes:** PascalCase (e.g., `UserRepository`)
- **Variables:** camelCase (e.g., `userName`)
- **Constants:** UPPER_SNAKE_CASE (e.g., `API_BASE_URL`)

## Import Organization

```dart
// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Project imports (relative)
import '../../domain/entities/user.dart';
import '../viewmodels/auth_viewmodel.dart';
```
