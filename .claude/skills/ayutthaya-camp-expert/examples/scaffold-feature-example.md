# Example: Scaffolding a New Feature

## Scenario

User wants to add an **in-app notifications** feature where users can see notifications about:
- New class schedules
- Payment confirmations
- Class cancellations
- General announcements

## Step-by-Step Workflow

### 1. User Request

> "Create a new in-app notifications feature with Firebase Cloud Messaging"

### 2. Skill Activation

The skill detects keywords: "new feature", "notifications"

### 3. Clarifying Questions

**Skill asks:**

1. What data should a notification contain?
   - **Answer:** Title, body, timestamp, read status, notification type, target user

2. Should notifications be stored in Firestore?
   - **Answer:** Yes, for persistence

3. Who can create notifications?
   - **Answer:** Admins only, users can only read their own

4. Real-time updates needed?
   - **Answer:** Yes, use Firestore listeners

### 4. Generate Scaffold

```bash
python .claude/skills/ayutthaya-camp-expert/scripts/scaffold_feature.py notifications
```

**Output:**
```
📁 Project root: C:\Users\exequ\Documents\Proyectos\Flutter\ayutthaya_camp
🚀 Scaffolding feature: notifications
📂 Target: C:\Users\exequ\Documents\Proyectos\Flutter\ayutthaya_camp\lib\features\notifications

✅ Created: lib/features/notifications/data/dto
✅ Created: lib/features/notifications/data/repositories
✅ Created: lib/features/notifications/domain/entities
✅ Created: lib/features/notifications/domain/repositories
✅ Created: lib/features/notifications/presentation/pages
✅ Created: lib/features/notifications/presentation/viewmodels
✅ Created: lib/features/notifications/presentation/widgets

📝 Generating files from templates...

✅ Generated: lib/features/notifications/domain/entities/notification.dart
✅ Generated: lib/features/notifications/domain/repositories/notification_repository.dart
✅ Generated: lib/features/notifications/data/dto/notification_dto.dart
✅ Generated: lib/features/notifications/data/repositories/notification_repository_impl.dart
✅ Generated: lib/features/notifications/presentation/viewmodels/notification_viewmodel.dart
✅ Generated: lib/features/notifications/presentation/pages/notification_page.dart

✅ Successfully generated 6/6 files

📋 Generating Firestore rules snippet...
✅ Generated: lib/features/notifications/firestore_rules_snippet.txt

🎉 Feature 'notifications' scaffolded successfully!

📝 Next steps:

1. Review generated files in lib/features/notifications/
2. Implement TODO items in each file
3. Add NotificationViewModel to lib/app/app.dart providers
4. Add navigation route for NotificationPage
5. Update firestore.rules with snippet from firestore_rules_snippet.txt
6. Run: flutter analyze
7. Run: flutter test
```

### 5. Customize Entity

**Edit:** `lib/features/notifications/domain/entities/notification.dart`

```dart
class Notification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? data; // Extra metadata

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.updatedAt,
    this.data,
  });

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? data,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      data: data ?? this.data,
    );
  }
}

enum NotificationType {
  classSchedule,
  paymentConfirmation,
  classCancellation,
  announcement,
}
```

### 6. Update DTO

**Edit:** `lib/features/notifications/data/dto/notification_dto.dart`

Add fields to match entity:

```dart
class NotificationDTO {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // Store enum as string
  final bool isRead;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Map<String, dynamic>? data;

  // ... fromFirestore, toFirestore, toEntity, fromEntity methods
}
```

### 7. Register ViewModel

**Edit:** `lib/app/app.dart`

```dart
MultiProvider(
  providers: [
    // Existing providers...
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(AuthRepositoryImpl()),
    ),
    ChangeNotifierProvider(
      create: (_) => DashboardViewModel(DashboardRepositoryImpl()),
    ),

    // Add new provider
    ChangeNotifierProvider(
      create: (_) => NotificationViewModel(NotificationRepositoryImpl()),
    ),
  ],
  child: MaterialApp(...),
)
```

### 8. Add Navigation Route

**Option A:** Add to bottom navigation (ShellPage)

**Option B:** Add as route in MaterialApp

```dart
MaterialApp(
  routes: {
    '/': (context) => const ShellPage(),
    '/login': (context) => const LoginPage(),
    '/notifications': (context) => const NotificationPage(), // New
  },
)
```

**Option C:** Add to dashboard as a card/button

```dart
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
  },
  child: Card(
    child: ListTile(
      leading: Icon(Icons.notifications),
      title: Text('Notificaciones'),
      trailing: Consumer<NotificationViewModel>(
        builder: (context, viewModel, _) {
          final unread = viewModel.unreadCount;
          return unread > 0
              ? Badge(label: Text('$unread'))
              : SizedBox.shrink();
        },
      ),
    ),
  ),
)
```

### 9. Update Firestore Rules

**Copy snippet from:** `lib/features/notifications/firestore_rules_snippet.txt`

**Add to:** `firestore.rules`

```javascript
// ============================================
// NOTIFICATIONS - User manages own notifications
// ============================================
match /notifications/{notificationId} {
  // Read: user can read own notifications, admin can read all
  allow read: if request.auth != null && (
    resource.data.userId == request.auth.uid ||
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
  );

  // Create: only admins can create notifications
  allow create: if request.auth != null &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';

  // Update: user can update own (mark as read), admin can update all
  allow update: if request.auth != null && (
    resource.data.userId == request.auth.uid ||
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
  );

  // Delete: only admins
  allow delete: if request.auth != null &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

**Deploy rules:**
```bash
firebase deploy --only firestore:rules
```

### 10. Test Implementation

```bash
# Code quality
flutter analyze

# Format code
dart format .

# Run tests (create tests first)
flutter test

# Run app
flutter run
```

### 11. Add to Admin Panel (Optional)

Create admin page to send notifications:

```dart
// lib/features/admin/presentation/pages/admin_notifications_page.dart

class AdminNotificationsPage extends StatelessWidget {
  void _sendNotification(BuildContext context) {
    final viewModel = context.read<NotificationViewModel>();

    final notification = Notification(
      id: FirebaseFirestore.instance.collection('notifications').doc().id,
      userId: 'all', // Or specific user ID
      title: 'New Class Schedule',
      body: 'Check out the new yoga class on Mondays!',
      type: NotificationType.classSchedule,
      createdAt: DateTime.now(),
    );

    viewModel.create(notification);
  }
}
```

### 12. Add Real-Time Listener

**In dashboard or shell page:**

```dart
@override
void initState() {
  super.initState();

  final authViewModel = context.read<AuthViewModel>();
  final notificationViewModel = context.read<NotificationViewModel>();

  if (authViewModel.user != null) {
    // Start watching notifications
    notificationViewModel.watchAll(authViewModel.user!.id);
  }
}
```

### 13. Add Badge to Bottom Navigation

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Inicio',
    ),
    // ...
    BottomNavigationBarItem(
      icon: Consumer<NotificationViewModel>(
        builder: (context, viewModel, _) {
          final unread = viewModel.unreadCount;
          return Badge(
            label: Text('$unread'),
            isLabelVisible: unread > 0,
            child: Icon(Icons.notifications),
          );
        },
      ),
      label: 'Notificaciones',
    ),
  ],
)
```

### 14. Final Verification

```bash
# Check everything compiles
flutter build apk --debug

# Run on device
flutter run
```

## Result

Complete notifications feature with:

✅ Clean Architecture structure
✅ Firestore integration
✅ Real-time updates
✅ Admin-only creation
✅ User read/unread tracking
✅ Navigation integration
✅ Firestore security rules
✅ Tests (to be written)

**Time saved:** ~2-3 hours of boilerplate coding

## Testing the Feature

### Manual Test

1. **As Admin:**
   - Navigate to admin panel
   - Create a notification for a specific user
   - Verify it appears in Firestore

2. **As User:**
   - Open notifications page
   - See new notification
   - Mark as read
   - Verify badge count decreases

3. **Real-time:**
   - Have two devices/emulators running
   - Send notification from one
   - Verify it appears instantly on the other

### Unit Tests (to write)

```dart
// test/features/notifications/viewmodels/notification_viewmodel_test.dart

void main() {
  group('NotificationViewModel', () {
    test('loadAll fetches notifications for user', () async {
      final mockRepo = MockNotificationRepository();
      final viewModel = NotificationViewModel(mockRepo);

      when(mockRepo.getAllNotifications('user123'))
          .thenAnswer((_) async => [
        Notification(
          id: '1',
          userId: 'user123',
          title: 'Test',
          body: 'Body',
          type: NotificationType.announcement,
          createdAt: DateTime.now(),
        ),
      ]);

      await viewModel.loadAll('user123');

      expect(viewModel.notifications.length, 1);
      expect(viewModel.isLoading, false);
    });

    test('markAsRead updates notification', () async {
      final mockRepo = MockNotificationRepository();
      final viewModel = NotificationViewModel(mockRepo);

      final notification = Notification(
        id: '1',
        userId: 'user123',
        title: 'Test',
        body: 'Body',
        type: NotificationType.announcement,
        isRead: false,
        createdAt: DateTime.now(),
      );

      viewModel.notifications.add(notification);

      await viewModel.markAsRead('1');

      expect(viewModel.notifications[0].isRead, true);
    });
  });
}
```

## Extensions

### Add Push Notifications (FCM)

1. Install package:
```yaml
dependencies:
  firebase_messaging: ^15.1.3
```

2. Create service:
```dart
// lib/core/services/fcm_service.dart
class FCMService {
  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    // Save token to user document
  }
}
```

3. Handle notifications:
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Show local notification
  // Update notification collection
});
```

4. Create Cloud Function to send FCM:
```typescript
// functions/src/functions/sendNotification.ts
export const sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();
    const user = await admin.firestore().collection('users').doc(notification.userId).get();
    const fcmToken = user.data()?.fcmToken;

    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
      });
    }
  });
```

## Summary

**Scaffolding a feature with the skill:**

1. Request feature with description
2. Answer clarifying questions
3. Run scaffold script
4. Customize generated code
5. Register ViewModel
6. Add navigation
7. Update Firestore rules
8. Test
9. Extend as needed

**Time:** ~30 minutes (vs 3+ hours manual)

**Quality:** Consistent architecture, best practices built-in
