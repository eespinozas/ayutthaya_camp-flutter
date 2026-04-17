# Ayutthaya Camp Project Conventions

## Naming Conventions

### Files
- **Dart files:** `snake_case.dart`
  - ✅ `user_repository.dart`
  - ❌ `UserRepository.dart`
  - ❌ `user-repository.dart`

- **Test files:** `{filename}_test.dart`
  - ✅ `user_repository_test.dart`

- **Python scripts:** `snake_case.py`
  - ✅ `seed_firebase.py`

- **Shell scripts:** `kebab-case.sh`
  - ✅ `setup-android-signing.sh`

### Classes
- **PascalCase**
  - ✅ `UserRepository`
  - ✅ `AuthViewModel`
  - ❌ `userRepository`

### Variables
- **camelCase**
  - ✅ `userName`
  - ✅ `isLoading`
  - ❌ `user_name`

### Constants
- **UPPER_SNAKE_CASE**
  - ✅ `API_BASE_URL`
  - ✅ `MAX_UPLOAD_SIZE`

### Private Members
- **Prefix with underscore**
  - ✅ `_repository`
  - ✅ `_isLoading`

## Directory Structure

### Features
```
lib/features/{feature_name}/
├── data/
│   ├── dto/
│   ├── api/ (optional)
│   └── repositories/
├── domain/
│   ├── entities/
│   └── repositories/
└── presentation/
    ├── pages/
    ├── viewmodels/
    └── widgets/
```

### Services
```
lib/core/services/
├── auth_service.dart
├── storage_service.dart
└── notification_service.dart
```

## Git Conventions

### Branch Naming
- **Feature:** `feature/{feature-name}`
  - ✅ `feature/in-app-notifications`

- **Bugfix:** `bugfix/{issue-description}`
  - ✅ `bugfix/payment-approval-stuck`

- **Hotfix:** `hotfix/{critical-issue}`
  - ✅ `hotfix/email-verification-broken`

- **Test:** `test/{test-name}`
  - ✅ `test/ci-setup`

### Commit Messages

**Format:** Imperative mood, present tense

✅ **Good:**
```
Add in-app notifications feature
Fix payment approval loading state
Update Firebase rules for bookings
Refactor auth service to use repository pattern
```

❌ **Bad:**
```
Added notifications
Fixed bug
WIP
Updated stuff
```

**Conventional Commits (optional but preferred):**
```
feat: Add in-app notifications
fix: Resolve payment approval loading issue
docs: Update README with setup instructions
refactor: Extract auth logic to repository
test: Add unit tests for AuthViewModel
```

### Tag Format
- **Releases:** `vX.Y.Z`
  - ✅ `v1.2.3`
  - ❌ `1.2.3`
  - ❌ `release-1.2.3`

## Code Style

### Dart Formatting
- **Use `dart format`** before committing
```bash
dart format .
```

### Import Organization

```dart
// 1. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 2. Package imports (alphabetical)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// 3. Project imports (relative, alphabetical)
import '../../domain/entities/user.dart';
import '../viewmodels/auth_viewmodel.dart';
```

### Widget Constructors
- **Always use const** when possible
```dart
✅ const Text('Hello')
❌ Text('Hello')

✅ const SizedBox(height: 16)
❌ SizedBox(height: 16)
```

### String Literals
- **Single quotes** for strings (Dart convention)
```dart
✅ final name = 'John';
❌ final name = "John";
```

- **Use string interpolation** instead of concatenation
```dart
✅ 'User: $userName'
✅ 'Count: ${items.length}'
❌ 'User: ' + userName
```

## Flutter Specific

### StatelessWidget vs StatefulWidget
- Use **StatelessWidget** when no internal state
- Use **StatefulWidget** when managing local UI state
- Use **ViewModels** for business logic state

### Keys
```dart
// For lists
ListView.builder(
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      ...
    );
  },
)

// For widgets that might rebuild
const MyWidget(key: ValueKey('unique-key'))
```

### Async/Await
```dart
// Always await async calls
✅ await _repository.getUsers();
❌ _repository.getUsers(); // Warning: unawaited futures

// Use try-catch
try {
  await _repository.createUser(user);
} catch (e) {
  print('Error: $e');
}
```

## Firebase Conventions

### Collection Names
- **Plural, snake_case**
  - ✅ `users`, `bookings`, `class_schedules`
  - ❌ `User`, `booking`, `classSchedule`

### Document IDs
- **Use Firestore auto-generated IDs** when possible
```dart
✅ final docRef = collection.doc(); // Auto-generated
final id = docRef.id;

❌ final docRef = collection.doc('custom-id'); // Only if needed
```

### Field Names
- **camelCase**
```javascript
{
  "userId": "abc123",
  "createdAt": Timestamp,
  "isActive": true
}
```

### Timestamps
- **Use Firestore Timestamp**
```dart
✅ createdAt: FieldValue.serverTimestamp()
❌ createdAt: DateTime.now().toString()
```

## Testing Conventions

### Test File Structure
```dart
void main() {
  group('AuthViewModel', () {
    test('login sets user when successful', () async {
      // Arrange
      final mockRepo = MockAuthRepository();
      final viewModel = AuthViewModel(mockRepo);

      // Act
      await viewModel.login('email', 'password');

      // Assert
      expect(viewModel.user, isNotNull);
    });
  });
}
```

### Test Naming
- **Descriptive, complete sentences**
```dart
✅ test('loadItems sets loading state to true during fetch', () {});
❌ test('loading', () {});
```

## Documentation

### File Headers
```dart
/// Repository implementation for User data access.
///
/// Uses Firebase Firestore as the backend.
class UserRepositoryImpl implements UserRepository {
  ...
}
```

### Public Methods
```dart
/// Fetches all active users from Firestore.
///
/// Returns a list of [User] entities sorted by creation date.
/// Throws [Exception] if fetch fails.
Future<List<User>> getActiveUsers() async {
  ...
}
```

### TODO Comments
```dart
// TODO: Add pagination support
// TODO(yourname): Refactor to use streams
// FIXME: Memory leak when disposing
```

## CI/CD Conventions

### Workflow Triggers
- **CI:** Runs on PR and push to `main`
- **Release:** Runs on tag `vX.Y.Z`

### Deployment Tracks
- **Android:**
  - `internal` - Internal testing (default)
  - `alpha` - Alpha testers
  - `beta` - Beta testers
  - `production` - Public release

- **iOS:**
  - `testflight` - TestFlight (default)
  - `appstore` - App Store

## Security Conventions

### Secrets
- **Never commit:**
  - Firebase service accounts (`*service-account.json`)
  - Android keystores (`*.jks`, `*.keystore`)
  - iOS certificates (`*.p12`, `*.mobileprovision`)
  - API keys in code
  - `android/key.properties`

- **Always use:**
  - `.env` files for development
  - GitHub Secrets for CI/CD
  - Firebase Remote Config for runtime config

### Firestore Rules
- **Default deny:** `allow read, write: if false;`
- **Explicit permissions:** Grant only what's needed
- **Role-based access:** Use `role` field in user docs

```javascript
// ✅ Good
allow read: if request.auth.uid == resource.data.userId;

// ❌ Bad
allow read, write: if true; // Wide open!
```

## Version Format

### pubspec.yaml
```yaml
version: MAJOR.MINOR.PATCH+BUILD_NUMBER
version: 1.2.3+45
```

- **MAJOR:** Breaking changes
- **MINOR:** New features (backwards compatible)
- **PATCH:** Bug fixes
- **BUILD_NUMBER:** Auto-increment (use git commit count)

## Error Messages

### User-Facing
- **Spanish** (app is in Spanish)
- **Clear and actionable**
```dart
✅ 'Error al cargar los pagos. Por favor, intenta nuevamente.'
❌ 'Exception: Null pointer'
```

### Developer-Facing
- **English** (logs, exceptions)
- **Include context**
```dart
✅ throw Exception('Failed to fetch user: userId=$userId, error=$e');
❌ throw Exception('Error');
```

## Pull Request Guidelines

1. **Title:** Clear, imperative
   - ✅ "Add in-app notifications feature"
   - ❌ "Updates"

2. **Description:**
   - What changed?
   - Why?
   - How to test?

3. **Checklist:**
   - [ ] `flutter analyze` passes
   - [ ] `flutter test` passes
   - [ ] Code formatted with `dart format`
   - [ ] No secrets committed
   - [ ] README updated (if needed)

## Release Checklist

Before creating a release:

1. [ ] All tests pass
2. [ ] Code quality checks pass (SonarCloud)
3. [ ] Version bumped in `pubspec.yaml`
4. [ ] CHANGELOG updated (if applicable)
5. [ ] No console logs or debug code
6. [ ] All TODOs addressed or documented
7. [ ] Firebase rules deployed
8. [ ] Cloud Functions deployed
9. [ ] Manual testing completed
10. [ ] Backup of keystores/certs verified

## References

- **Dart Style Guide:** https://dart.dev/guides/language/effective-dart/style
- **Flutter Best Practices:** https://flutter.dev/docs/testing/best-practices
- **Conventional Commits:** https://www.conventionalcommits.org/
