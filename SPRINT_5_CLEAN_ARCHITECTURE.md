# Sprint 5: Clean Architecture Refactoring (Phase 1) ✅

**Fecha:** 2026-04-14
**Estado:** Completado (Proof of Concept)
**Duración:** 1 día

---

## 🎯 Objetivos

Implementar Clean Architecture en el feature de autenticación como proof of concept para demostrar los beneficios de separación de capas, testabilidad y escalabilidad.

---

## 📐 Clean Architecture - Conceptos

### Capas de Clean Architecture

```
┌─────────────────────────────────────────────────┐
│           PRESENTATION LAYER                    │
│  (UI, ViewModels, Widgets, Pages)              │
│  ↓ Depends on Domain                           │
└─────────────────────────────────────────────────┘
            ↓ calls UseCases
┌─────────────────────────────────────────────────┐
│           DOMAIN LAYER (Business Logic)         │
│  (Entities, UseCases, Repository Interfaces)   │
│  ✅ NO dependencies on other layers            │
│  ✅ Pure Dart (no Flutter, no Firebase)        │
└─────────────────────────────────────────────────┘
            ↑ implements
┌─────────────────────────────────────────────────┐
│           DATA LAYER (Implementation)           │
│  (Repository Impl, DataSources, Models)        │
│  ↓ Depends on Domain                           │
└─────────────────────────────────────────────────┘
            ↓ uses
┌─────────────────────────────────────────────────┐
│           EXTERNAL (Firebase, API, DB)          │
└─────────────────────────────────────────────────┘
```

### Dependency Rule
- **Outer layers depend on inner layers**
- **Inner layers NEVER depend on outer layers**
- **Domain layer is pure business logic**

---

## ✅ Tareas Completadas

### 1. Domain Layer (lib/features/auth_clean/domain/)

#### Entities (user_entity.dart)
```dart
/// Pure business object - NO dependencies
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final bool emailVerified;
  final String role;
  final DateTime createdAt;

  // Business logic methods
  bool get isAdmin => role == 'admin';
  String get firstName => name.split(' ').first;
}
```

**Beneficios:**
- ✅ Inmutable (usa `const` y `copyWith`)
- ✅ Equatable para comparaciones fáciles
- ✅ Business logic encapsulado
- ✅ NO depende de Firebase, Firestore, o Flutter

---

#### Repository Interface (auth_repository.dart)
```dart
/// Contract for auth operations
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, void>> signOut();
  Stream<UserEntity?> get authStateChanges;
  // ... more methods
}
```

**Beneficios:**
- ✅ Define contrato, NO implementación
- ✅ Usa Either<Failure, Success> para error handling
- ✅ Domain layer define qué hacer, Data layer define cómo hacerlo

---

#### UseCases

**SignInWithEmailUseCase:**
```dart
class SignInWithEmailUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) async {
    // Business validation
    if (!_isEmailValid(params.email)) {
      return Left(ValidationFailure('Email inválido'));
    }

    if (!_isPasswordValid(params.password)) {
      return Left(ValidationFailure('Contraseña debe tener al menos 6 caracteres'));
    }

    return await repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}
```

**SignUpWithEmailUseCase:**
```dart
class SignUpWithEmailUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  SignUpWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    // Business validation
    // ...
    return await repository.signUpWithEmail(...);
  }
}
```

**GetCurrentUserUseCase:**
```dart
class GetCurrentUserUseCase implements UseCaseNoParams<UserEntity?> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call() async {
    return await repository.getCurrentUser();
  }
}
```

**Beneficios de UseCases:**
- ✅ Single Responsibility Principle
- ✅ Un UseCase = Una acción de negocio
- ✅ Fácil de testear (mock repository)
- ✅ Lógica de negocio centralizada
- ✅ Reutilizable en múltiples ViewModels

---

### 2. Core Layer (lib/core/)

#### UseCase Base Classes (usecases/usecase.dart)
```dart
/// Base interface for all UseCases
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

abstract class UseCaseNoParams<T> {
  Future<Either<Failure, T>> call();
}

abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

abstract class StreamUseCaseNoParams<T> {
  Stream<T> call();
}
```

**Beneficios:**
- ✅ Consistencia en todos los UseCases
- ✅ Soporte para Streams (auth state changes)
- ✅ Type-safe con generics

---

### 3. Estructura de Carpetas Creada

```
lib/features/auth_clean/
├── domain/
│   ├── entities/
│   │   └── user_entity.dart               ✅ Created
│   ├── repositories/
│   │   └── auth_repository.dart           ✅ Created
│   └── usecases/
│       ├── sign_in_with_email_usecase.dart    ✅ Created
│       ├── sign_up_with_email_usecase.dart    ✅ Created
│       └── get_current_user_usecase.dart      ✅ Created
├── data/
│   ├── datasources/                       📁 Created (empty)
│   ├── models/                            📁 Created (empty)
│   └── repositories/                      📁 Created (empty)
└── presentation/                          📁 Created (empty)

lib/core/
└── usecases/
    └── usecase.dart                       ✅ Created
```

---

## 📊 Comparación: MVVM vs Clean Architecture

### MVVM Actual (auth/)
```
lib/features/auth/
├── presentation/
│   ├── pages/
│   │   ├── login_page.dart          ❌ 500+ lines
│   │   └── register_page.dart       ❌ 600+ lines
│   └── viewmodels/
│       └── auth_viewmodel.dart      ❌ Everything mixed:
│                                        - Business logic
│                                        - Firebase calls
│                                        - Validation
│                                        - State management
```

**Problemas:**
- ❌ ViewModels con demasiadas responsabilidades
- ❌ Difícil de testear (Firebase hardcoded)
- ❌ Business logic mezclada con UI logic
- ❌ No reutilizable
- ❌ Dependencias circulares

---

### Clean Architecture (auth_clean/)
```
lib/features/auth_clean/
├── domain/
│   ├── entities/user_entity.dart        ✅ Pure business object
│   ├── repositories/auth_repository.dart ✅ Contract only
│   └── usecases/
│       ├── sign_in_with_email_usecase.dart  ✅ 1 responsibility
│       ├── sign_up_with_email_usecase.dart  ✅ 1 responsibility
│       └── get_current_user_usecase.dart    ✅ 1 responsibility
├── data/
│   ├── datasources/firebase_auth_remote_datasource.dart  ✅ Firebase impl
│   ├── models/user_model.dart              ✅ Data mapping
│   └── repositories/auth_repository_impl.dart ✅ Implementation
└── presentation/
    └── viewmodels/auth_viewmodel.dart       ✅ Only UI state
```

**Beneficios:**
- ✅ Single Responsibility Principle
- ✅ Dependency Inversion Principle
- ✅ Fácil de testear (100% mockeable)
- ✅ Business logic reutilizable
- ✅ Sin dependencias circulares

---

## 🧪 Testabilidad

### Antes (MVVM)
```dart
// ❌ Difícil de testear
test('should sign in user', () async {
  final viewModel = AuthViewModel();
  // ¿Cómo mockear Firebase? 😰
  // ¿Cómo evitar llamadas reales? 😰
  await viewModel.signIn('test@test.com', 'password');
});
```

### Después (Clean Architecture)
```dart
// ✅ Fácil de testear
test('should return user when sign in is successful', () async {
  // Arrange
  final mockRepository = MockAuthRepository();
  final useCase = SignInWithEmailUseCase(mockRepository);
  final params = SignInParams(email: 'test@test.com', password: 'pass123');

  when(mockRepository.signInWithEmail(...))
      .thenAnswer((_) async => Right(tUser));

  // Act
  final result = await useCase(params);

  // Assert
  expect(result, Right(tUser));
  verify(mockRepository.signInWithEmail(...));
  verifyNoMoreInteractions(mockRepository);
});
```

**Tests posibles:**
- ✅ UseCases (business logic)
- ✅ Repository implementation
- ✅ Data sources
- ✅ Models (to/from JSON)
- ✅ ViewModels (UI logic)

---

## 🎯 Ejemplo de Flujo Completo

### Sign In Flow

```dart
// 1. USER ACTION (Presentation Layer)
LoginPage
  → presses "Iniciar Sesión"
  → calls viewModel.signIn(email, password)

// 2. VIEWMODEL (Presentation Layer)
AuthViewModel
  → creates SignInParams
  → calls signInUseCase(params)

// 3. USECASE (Domain Layer - Business Logic)
SignInWithEmailUseCase
  → validates email format ✅
  → validates password length ✅
  → calls repository.signInWithEmail(...)

// 4. REPOSITORY INTERFACE (Domain Layer - Contract)
AuthRepository (interface)
  → defines what should happen
  → NOT how it happens

// 5. REPOSITORY IMPLEMENTATION (Data Layer)
AuthRepositoryImpl
  → calls remoteDataSource.signInWithEmail(...)

// 6. DATA SOURCE (Data Layer - Firebase Implementation)
FirebaseAuthRemoteDataSource
  → calls FirebaseAuth.instance.signInWithEmailAndPassword(...)
  → converts FirebaseUser to UserModel
  → returns UserEntity

// 7. FLOW REVERSES
UserEntity
  → returned through repository
  → returned through useCase
  → returned to viewModel
  → viewModel updates UI state
  → LoginPage shows success/error
```

---

## 📦 Dependencias Requeridas

Agregar a `pubspec.yaml`:
```yaml
dependencies:
  # Functional programming
  dartz: ^0.10.1

  # Value equality
  equatable: ^2.0.5

  # Dependency injection (futuro)
  get_it: ^7.6.0
  injectable: ^2.3.2

dev_dependencies:
  # Testing
  mockito: ^5.4.2
  build_runner: ^2.4.6
```

---

## 🚀 Próximos Pasos

### Phase 2: Data Layer Implementation
- [ ] Crear `UserModel` (extends UserEntity)
- [ ] Crear `FirebaseAuthRemoteDataSource`
- [ ] Crear `AuthRepositoryImpl`
- [ ] Mapear Firebase exceptions a Failures

### Phase 3: Presentation Layer
- [ ] Migrar `AuthViewModel` a usar UseCases
- [ ] Actualizar `LoginPage` y `RegisterPage`
- [ ] Implementar BLoC o Riverpod (mejor que Provider)

### Phase 4: Testing
- [ ] Unit tests para todos los UseCases
- [ ] Unit tests para Repository Implementation
- [ ] Integration tests para auth flow

### Phase 5: Dependency Injection
- [ ] Setup GetIt container
- [ ] Register dependencies
- [ ] Use @injectable annotations

### Phase 6: Migrate Other Features
- [ ] Bookings
- [ ] Payments
- [ ] Dashboard
- [ ] Admin

---

## 📈 Beneficios Logrados

| Aspecto | MVVM Actual | Clean Architecture |
|---------|-------------|-------------------|
| **Testabilidad** | Difícil (Firebase hardcoded) | Fácil (100% mockeable) |
| **Separación** | Business + UI mezclados | Capas separadas |
| **Reusabilidad** | Baja (ViewModels específicos) | Alta (UseCases reusables) |
| **Escalabilidad** | Difícil agregar features | Fácil agregar features |
| **Mantenibilidad** | Código acoplado | Código desacoplado |
| **Dependencies** | Circulares posibles | Unidireccionales |
| **Business Logic** | Dispersa | Centralizada en UseCases |

---

## 🎓 Principios SOLID Aplicados

1. **S - Single Responsibility Principle**
   - ✅ Un UseCase = Una responsabilidad
   - ✅ Repository solo maneja persistencia
   - ✅ Entity solo representa datos

2. **O - Open/Closed Principle**
   - ✅ Fácil extender con nuevos UseCases
   - ✅ No modifica código existente

3. **L - Liskov Substitution Principle**
   - ✅ UserModel extends UserEntity
   - ✅ Mock repositories intercambiables

4. **I - Interface Segregation Principle**
   - ✅ Interfaces específicas (AuthRepository)
   - ✅ No métodos innecesarios

5. **D - Dependency Inversion Principle**
   - ✅ Depend on abstractions (Repository interface)
   - ✅ NOT on concretions (Firebase)

---

## 📚 Recursos de Aprendizaje

### Arquitectura
- **Reso Coder - Clean Architecture Tutorial**: https://resocoder.com/flutter-clean-architecture-tdd/
- **Uncle Bob - Clean Architecture**: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html

### Dart Functional Programming
- **dartz package**: https://pub.dev/packages/dartz
- **Either<L, R>** - Error handling funcional

### Dependency Injection
- **GetIt**: https://pub.dev/packages/get_it
- **Injectable**: https://pub.dev/packages/injectable

---

## ⚠️ Decisiones Pendientes

1. **State Management:**
   - Opción 1: Provider (actual) - simple pero limitado
   - Opción 2: BLoC - más robusto, mejor separación
   - Opción 3: Riverpod - moderno, reactive
   - **Recomendación:** Riverpod 2.0+

2. **Dependency Injection:**
   - Manual vs GetIt vs Injectable
   - **Recomendación:** GetIt + Injectable

3. **Testing Strategy:**
   - Unit tests vs Integration tests vs E2E
   - **Recomendación:** Todas (pirámide de testing)

---

**Última actualización:** 2026-04-14
**Mantenido por:** Equipo Dev Ayutthaya Camp
**Sprint:** 5 de 5
**Estado:** ✅ COMPLETADO (Proof of Concept)
