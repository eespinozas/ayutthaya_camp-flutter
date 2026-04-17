# Propuesta Arquitectural - Ayutthaya Camp App

## Resumen Ejecutivo

Esta propuesta arquitectural se basa en el análisis del código actual y busca **evolucionar gradualmente** la arquitectura actual hacia un sistema más mantenible, escalable y testeable, sin reescribir todo desde cero.

**Filosofía**: Refactorización incremental, no reescritura completa.

---

## 1. Análisis de la Arquitectura Actual

### 1.1 Fortalezas Detectadas

✅ **Feature-based structure**: La organización por features es excelente para escalar
✅ **Provider + MVVM**: Patrón simple y efectivo para el tamaño actual
✅ **Separación de concerns**: Models, services y viewmodels bien diferenciados
✅ **Firebase bien integrado**: Uso correcto de Firestore, Auth y Storage
✅ **Sistema de diseño iniciado**: Carpeta `theme/` con colores, estilos y espaciados

### 1.2 Debilidades Detectadas

❌ **Arquitectura inconsistente**: Algunos features tienen domain/data/presentation, otros no
❌ **Falta capa de Repository**: Services acceden directamente a Firestore
❌ **ViewModels con lógica de negocio**: Deberían delegar a use cases
❌ **Duplicación de código**: Widgets similares en diferentes pantallas
❌ **Falta de inyección de dependencias**: Todo se crea directamente con `new`
❌ **Testing limitado**: Difícil testear por acoplamiento a Firebase

---

## 2. Arquitectura Objetivo: Clean Architecture Pragmática

### 2.1 Por Qué Clean Architecture

- **Testeable**: Lógica de negocio independiente de Firebase
- **Mantenible**: Cambios aislados por capas
- **Escalable**: Fácil añadir nuevas features
- **Framework-independent**: Podríamos cambiar Provider por Bloc sin reescribir todo

### 2.2 Capas Propuestas

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Pages      │  │   Widgets    │  │  ViewModels  │      │
│  │ (UI Screens) │  │ (Reusables)  │  │ (State Mgmt) │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                           ▲                                  │
├───────────────────────────┼──────────────────────────────────┤
│                    Domain Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Entities    │  │  Use Cases   │  │ Repositories │      │
│  │ (Pure Dart)  │  │ (Business    │  │ (Interfaces) │      │
│  │              │  │   Logic)     │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                           ▲                                  │
├───────────────────────────┼──────────────────────────────────┤
│                     Data Layer                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Models     │  │ Repositories │  │ Data Sources │      │
│  │    (DTOs)    │  │    (Impl)    │  │  (Firebase)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Estructura de Carpetas Objetivo

```
lib/
├── core/
│   ├── config/
│   ├── di/                        # ← NUEVO: Dependency Injection
│   │   └── injection_container.dart
│   ├── error/                     # ← NUEVO: Manejo de errores
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/                   # ← NUEVO: Network utilities
│   ├── services/                  # Servicios compartidos
│   ├── theme/                     # ← MOVER desde lib/theme/
│   └── widgets/                   # Widgets globales
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/       # ← NUEVO
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/            # DTOs (toJson/fromJson)
│   │   │   └── repositories/      # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/          # ← NUEVO: Pure Dart objects
│   │   │   ├── repositories/      # ← NUEVO: Repository interfaces
│   │   │   └── usecases/          # ← NUEVO: Business logic
│   │   │       ├── login_user.dart
│   │   │       ├── register_user.dart
│   │   │       └── logout_user.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── viewmodels/        # ← SIMPLIFICADOS: solo state + UI logic
│   ├── bookings/                  # (misma estructura)
│   ├── payments/                  # (misma estructura)
│   └── ... (otros features)
└── main.dart
```

---

## 3. Plan de Migración Gradual (Por Fases)

### FASE 1: Fundaciones (Sprint 1-2)

#### 3.1.1 Crear Infraestructura Core

**Archivos a crear:**
```dart
// lib/core/error/failures.dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
```

```dart
// lib/core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class CacheException implements Exception {}
```

```dart
// lib/core/network/network_info.dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // Implementar con connectivity_plus
    return true;
  }
}
```

#### 3.1.2 Setup Dependency Injection (GetIt)

**Agregar dependencia:**
```yaml
# pubspec.yaml
dependencies:
  get_it: ^7.6.0
```

**Crear container:**
```dart
// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // Features - Auth
  sl.registerFactory(() => AuthViewModel(loginUser: sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));

  // Core
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
}
```

**Inicializar en main.dart:**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await di.init(); // ← Dependency injection setup
  runApp(const App());
}
```

#### 3.1.3 Centralizar Tema

**Mover `lib/theme/` a `lib/core/theme/`** y consolidar:

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      // ...
    ),
    textTheme: AppTextStyles.textTheme,
    // ...
  );
}
```

---

### FASE 2: Migrar Feature Auth (Sprint 3-4)

**Por qué Auth primero?** Es el feature más crítico y pequeño, ideal para aprender el patrón.

#### 3.2.1 Crear Entities (Domain Layer)

```dart
// lib/features/auth/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String email;
  final String name;
  final String role;
  final String membershipStatus;
  final DateTime? expirationDate;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.membershipStatus,
    this.expirationDate,
  });
}
```

#### 3.2.2 Crear Repository Interface (Domain Layer)

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart'; // Para Either<Failure, Success>
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, UserEntity>> register(String email, String password, String name);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> getCurrentUser();
}
```

**Agregar dependencia:**
```yaml
dependencies:
  dartz: ^0.10.1
```

#### 3.2.3 Crear Use Cases (Domain Layer)

```dart
// lib/features/auth/domain/usecases/login_user.dart
class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  Future<Either<Failure, UserEntity>> call(String email, String password) async {
    return await repository.login(email, password);
  }
}
```

```dart
// lib/features/auth/domain/usecases/register_user.dart
class RegisterUser {
  final AuthRepository repository;

  RegisterUser(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String name,
  }) async {
    return await repository.register(email, password, name);
  }
}
```

#### 3.2.4 Crear Data Sources (Data Layer)

```dart
// lib/features/auth/data/datasources/auth_remote_datasource.dart
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl(this.firebaseAuth, this.firestore);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final cred = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await firestore.collection('users').doc(cred.user!.uid).get();
      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Login failed');
    }
  }

  // ... otros métodos
}
```

#### 3.2.5 Crear Models (Data Layer)

```dart
// lib/features/auth/data/models/user_model.dart
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    required super.membershipStatus,
    super.expirationDate,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      membershipStatus: data['membershipStatus'] ?? 'none',
      expirationDate: data['expirationDate'] != null
          ? (data['expirationDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'membershipStatus': membershipStatus,
      'expirationDate': expirationDate != null
          ? Timestamp.fromDate(expirationDate!)
          : null,
    };
  }
}
```

#### 3.2.6 Implementar Repository (Data Layer)

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final user = await remoteDataSource.login(email, password);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  // ... otros métodos
}
```

#### 3.2.7 Refactorizar ViewModel (Presentation Layer)

```dart
// lib/features/auth/presentation/viewmodels/auth_viewmodel.dart
class AuthViewModel extends ChangeNotifier {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final LogoutUser logoutUser;

  // State
  bool _loading = false;
  String? _error;
  UserEntity? _user;

  bool get loading => _loading;
  String? get error => _error;
  UserEntity? get user => _user;
  bool get isLoggedIn => _user != null;

  AuthViewModel({
    required this.loginUser,
    required this.registerUser,
    required this.logoutUser,
  });

  Future<void> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await loginUser(email, password);

    result.fold(
      (failure) {
        _error = failure.message;
        _loading = false;
        notifyListeners();
      },
      (user) {
        _user = user;
        _loading = false;
        notifyListeners();
      },
    );
  }

  // ... otros métodos
}
```

---

### FASE 3: Migrar Features Críticos (Sprint 5-6)

**Orden sugerido:**
1. **Bookings** (agendamiento de clases)
2. **Payments** (pagos y aprobaciones)
3. **Plans** (gestión de planes)
4. **Dashboard** (visualización de datos)

**Proceso para cada feature:**
1. Crear entities
2. Crear repository interface
3. Crear use cases
4. Crear data sources
5. Crear models
6. Implementar repository
7. Refactorizar viewmodels
8. Actualizar DI container

---

### FASE 4: Widgets Reutilizables (Sprint 7)

#### 4.1 Crear Atomic Design System

```
lib/core/widgets/
├── atoms/                    # Componentes básicos
│   ├── app_button.dart
│   ├── app_text_field.dart
│   ├── app_loading_indicator.dart
│   └── app_error_message.dart
├── molecules/                # Combinaciones de atoms
│   ├── info_card.dart
│   ├── stat_card.dart
│   └── alert_banner.dart
├── organisms/                # Secciones completas
│   ├── navigation_bar.dart
│   ├── class_schedule_list.dart
│   └── payment_summary.dart
└── templates/                # Layouts completos
    ├── scrollable_page.dart
    └── dashboard_layout.dart
```

#### 4.2 Ejemplo: AppButton Reutilizable

```dart
// lib/core/widgets/atoms/app_button.dart
enum AppButtonType { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool loading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = switch (type) {
      AppButtonType.primary => AppColors.primary,
      AppButtonType.secondary => AppColors.secondary,
      AppButtonType.outline => Colors.transparent,
      AppButtonType.danger => AppColors.error,
    };

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: type == AppButtonType.outline
                ? BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
```

---

### FASE 5: Testing (Sprint 8-9)

#### 5.1 Estructura de Tests

```
test/
├── core/
│   ├── error/
│   └── network/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       └── viewmodels/
│   └── ... (otros features)
└── fixtures/                 # Datos mock para tests
    └── user_fixture.json
```

#### 5.2 Ejemplo: Test de Use Case

```dart
// test/features/auth/domain/usecases/login_user_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([AuthRepository])
void main() {
  late LoginUser usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginUser(mockRepository);
  });

  test('should return UserEntity when login is successful', () async {
    // Arrange
    const email = 'test@test.com';
    const password = 'password123';
    const userEntity = UserEntity(
      id: '1',
      email: email,
      name: 'Test User',
      role: 'student',
      membershipStatus: 'active',
    );

    when(mockRepository.login(email, password))
        .thenAnswer((_) async => const Right(userEntity));

    // Act
    final result = await usecase(email, password);

    // Assert
    expect(result, const Right(userEntity));
    verify(mockRepository.login(email, password));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return AuthFailure when credentials are invalid', () async {
    // Arrange
    const email = 'wrong@test.com';
    const password = 'wrongpass';
    const failure = AuthFailure('Invalid credentials');

    when(mockRepository.login(email, password))
        .thenAnswer((_) async => const Left(failure));

    // Act
    final result = await usecase(email, password);

    // Assert
    expect(result, const Left(failure));
    verify(mockRepository.login(email, password));
  });
}
```

#### 5.3 Ejemplo: Test de ViewModel

```dart
// test/features/auth/presentation/viewmodels/auth_viewmodel_test.dart
void main() {
  late AuthViewModel viewModel;
  late MockLoginUser mockLoginUser;

  setUp(() {
    mockLoginUser = MockLoginUser();
    viewModel = AuthViewModel(
      loginUser: mockLoginUser,
      registerUser: MockRegisterUser(),
      logoutUser: MockLogoutUser(),
    );
  });

  test('loading should be true during login', () async {
    // Arrange
    when(mockLoginUser(any, any))
        .thenAnswer((_) async => const Right(tUserEntity));

    // Act
    final future = viewModel.login('test@test.com', 'pass');

    // Assert - during execution
    expect(viewModel.loading, true);

    await future;

    // Assert - after completion
    expect(viewModel.loading, false);
  });
}
```

---

## 4. Mejoras Transversales

### 4.1 Manejo de Errores Centralizado

```dart
// lib/core/error/error_handler.dart
class ErrorHandler {
  static String getErrorMessage(Failure failure) {
    return switch (failure) {
      AuthFailure() => _getAuthErrorMessage(failure.message),
      ServerFailure() => 'Error del servidor. Intenta nuevamente.',
      CacheFailure() => 'Error al cargar datos locales.',
      NetworkFailure() => 'Sin conexión a internet.',
      _ => 'Error inesperado. Contacta soporte.',
    };
  }

  static String _getAuthErrorMessage(String code) {
    return switch (code) {
      'user-not-found' => 'Usuario no encontrado',
      'wrong-password' => 'Contraseña incorrecta',
      'email-already-in-use' => 'Email ya registrado',
      'weak-password' => 'Contraseña muy débil',
      _ => 'Error de autenticación',
    };
  }
}
```

### 4.2 Logging Estructurado

```dart
// lib/core/logging/app_logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
```

**Agregar dependencia:**
```yaml
dependencies:
  logger: ^2.0.2
```

### 4.3 Analytics y Tracking

```dart
// lib/core/analytics/analytics_service.dart
abstract class AnalyticsService {
  void logEvent(String name, Map<String, dynamic> parameters);
  void setUserId(String userId);
  void setUserProperty(String name, String value);
  void logScreen(String screenName);
}

class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void logEvent(String name, Map<String, dynamic> parameters) {
    _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  void setUserId(String userId) {
    _analytics.setUserId(id: userId);
  }

  @override
  void logScreen(String screenName) {
    _analytics.logScreenView(screenName: screenName);
  }

  // ... otros métodos
}
```

---

## 5. Optimizaciones de Performance

### 5.1 Paginación Mejorada

```dart
// lib/core/services/pagination_service.dart (MEJORADO)
class PaginatedData<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int totalCount;

  const PaginatedData({
    required this.items,
    this.lastDocument,
    this.hasMore = true,
    this.totalCount = 0,
  });
}

class PaginationService {
  static const int pageSize = 20;

  static Future<PaginatedData<T>> fetchPage<T>({
    required Query query,
    required T Function(DocumentSnapshot) fromSnapshot,
    DocumentSnapshot? lastDoc,
  }) async {
    Query paginatedQuery = query.limit(pageSize + 1); // +1 para detectar hasMore

    if (lastDoc != null) {
      paginatedQuery = paginatedQuery.startAfterDocument(lastDoc);
    }

    final snapshot = await paginatedQuery.get();
    final docs = snapshot.docs;

    final hasMore = docs.length > pageSize;
    final items = docs
        .take(pageSize)
        .map((doc) => fromSnapshot(doc))
        .toList();

    return PaginatedData(
      items: items,
      lastDocument: items.isNotEmpty ? docs[items.length - 1] : null,
      hasMore: hasMore,
      totalCount: items.length,
    );
  }
}
```

### 5.2 Caché Local con Hive

**Agregar dependencias:**
```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  hive_generator: ^2.0.0
```

**Ejemplo de uso:**
```dart
// lib/features/auth/data/datasources/auth_local_datasource.dart
abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box<Map<dynamic, dynamic>> userBox;

  AuthLocalDataSourceImpl(this.userBox);

  @override
  Future<UserModel?> getCachedUser() async {
    final userData = userBox.get('current_user');
    if (userData == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(userData));
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await userBox.put('current_user', user.toJson());
  }

  @override
  Future<void> clearCache() async {
    await userBox.clear();
  }
}
```

---

## 6. CI/CD y Quality Assurance

### 6.1 GitHub Actions Mejorado

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze code
        run: flutter analyze

      - name: Check formatting
        run: dart format --set-exit-if-changed .

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      - name: Build APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      - name: Build iOS
        run: flutter build ios --release --no-codesign
```

### 6.2 Pre-commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/sh

echo "Running Flutter analyzer..."
flutter analyze

if [ $? -ne 0 ]; then
  echo "Flutter analyzer failed. Commit aborted."
  exit 1
fi

echo "Running tests..."
flutter test

if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi

echo "Checking code formatting..."
dart format --set-exit-if-changed .

if [ $? -ne 0 ]; then
  echo "Code is not formatted. Run 'dart format .' and try again."
  exit 1
fi

exit 0
```

---

## 7. Roadmap de Implementación (Timeline)

| Sprint | Duración | Tareas Principales | Resultado Esperado |
|--------|----------|-------------------|-------------------|
| **Sprint 1-2** | 2 semanas | FASE 1: Fundaciones | Core infrastructure lista |
| **Sprint 3-4** | 2 semanas | FASE 2: Migrar Auth | Feature Auth con Clean Architecture |
| **Sprint 5-6** | 2 semanas | FASE 3: Migrar Bookings + Payments | Features críticos migrados |
| **Sprint 7** | 1 semana | FASE 4: Design System | Widgets reutilizables centralizados |
| **Sprint 8-9** | 2 semanas | FASE 5: Testing + QA | Coverage > 80% |
| **Sprint 10** | 1 semana | Refactoring + Optimización | Code cleanup, performance |

**Total estimado**: 10 sprints = ~20 semanas (~5 meses)

---

## 8. Métricas de Éxito

### 8.1 Métricas Técnicas
- **Code coverage**: > 80%
- **Build time**: < 3 minutos
- **App size**: < 50MB (Android APK)
- **Startup time**: < 2 segundos
- **Crash rate**: < 0.5%

### 8.2 Métricas de Calidad
- **Flutter analyze warnings**: 0
- **Duplicated code**: < 5%
- **Cyclomatic complexity**: < 10 por función
- **Technical debt ratio**: < 5%

### 8.3 Métricas de Negocio
- **Tiempo de aprobación de pagos**: < 24 horas
- **Tasa de conversión (registro → matrícula)**: > 60%
- **Tasa de asistencia**: > 70%
- **NPS (Net Promoter Score)**: > 50

---

## 9. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Breaking changes durante migración | Media | Alto | Feature flags + despliegue gradual |
| Resistencia del equipo a cambios | Baja | Medio | Capacitación + documentación clara |
| Deuda técnica acumulada | Alta | Alto | Code reviews + refactoring continuo |
| Performance degradation | Baja | Alto | Profiling + benchmarking continuo |
| Firebase costs escalation | Media | Medio | Monitoring + caching agresivo |

---

## 10. Recomendaciones Finales

### 10.1 DO's ✅
- **Migrar feature por feature**, no todo a la vez
- **Escribir tests desde el principio** para cada nueva capa
- **Documentar decisiones arquitecturales** (ADRs)
- **Code reviews obligatorios** antes de merge
- **Usar feature flags** para despliegues graduales

### 10.2 DON'Ts ❌
- **NO reescribir todo desde cero** (demasiado riesgo)
- **NO migrar sin tests** (receta para bugs)
- **NO sobre-ingenierizar** (KISS principle)
- **NO ignorar performance** durante refactoring
- **NO saltarse code reviews** por urgencia

---

## 11. Recursos Adicionales

### 11.1 Libros Recomendados
- **"Clean Architecture" by Robert C. Martin**
- **"Domain-Driven Design" by Eric Evans**
- **"Refactoring" by Martin Fowler**

### 11.2 Cursos y Tutoriales
- **ResoCoder - Flutter Clean Architecture Tutorial** (YouTube)
- **Reso Coder - TDD Clean Architecture** (curso completo)
- **Flutter Community - Best Practices**

### 11.3 Herramientas
- **SonarQube**: Análisis de calidad de código
- **Codemagic/Bitrise**: CI/CD para Flutter
- **Firebase Test Lab**: Testing en dispositivos reales
- **Sentry/Crashlytics**: Error tracking

---

**Última actualización**: 2026-04-14
**Autor**: Análisis automatizado + recomendaciones expertas
**Versión**: 1.0
**Estado**: Propuesta para aprobación
