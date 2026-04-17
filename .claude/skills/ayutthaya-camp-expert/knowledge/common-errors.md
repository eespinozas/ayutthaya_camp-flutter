# Common Errors and Solutions

## Firebase Errors

### 1. Service Account Not Found

**Error:**
```
ERROR: No se encontró el archivo: scripts/firebase-service-account.json
```

**Cause:**
Python scripts need Firebase Admin SDK credentials

**Solutions:**

Option 1: Environment variable
```bash
export FIREBASE_SERVICE_ACCOUNT=/path/to/service-account.json
python scripts/seed_firebase.py
```

Option 2: Default location
```bash
cp ~/Downloads/service-account.json scripts/firebase-service-account.json
python scripts/seed_firebase.py
```

Option 3: Command argument
```bash
python scripts/seed_firebase.py /path/to/service-account.json
```

**Prevention:**
- Never commit service account files
- Verify `.gitignore` includes `*service-account.json`

---

### 2. Permission Denied (Firestore)

**Error:**
```
[cloud_firestore/permission-denied] The caller does not have permission
```

**Cause:**
Firestore security rules blocking access

**Debug steps:**

1. Check user role:
```bash
python scripts/check_user.py user@example.com
```

2. Verify Firestore rules in Firebase Console

3. Check user document has `role` field:
```javascript
{
  "email": "user@example.com",
  "role": "admin", // or "user"
  "status": "active"
}
```

**Common rule patterns:**

User can read own data:
```javascript
allow read: if request.auth.uid == userId;
```

Admin can read all:
```javascript
allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
```

---

### 3. Firebase Not Initialized

**Error:**
```
[core/not-initialized] Firebase has not been initialized
```

**Cause:**
Missing `Firebase.initializeApp()` call

**Solution:**

Check `lib/main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

---

## Build Errors

### 4. Android Keystore Password Incorrect

**Error:**
```
Keystore was tampered with, or password was incorrect
```

**Cause:**
Password mismatch in `android/key.properties`

**Solution:**

1. Verify passwords in `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

2. Check keystore is in correct location:
```bash
ls -la android/app/upload-keystore.jks
```

3. If forgotten, regenerate keystore:
```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload -storetype JKS
```

**⚠️ Warning:** New keystore = can't update existing Play Store app

---

### 5. Version Code Already Exists

**Error:**
```
Version code 10 has already been used. Try another version code.
```

**Cause:**
Build number in `pubspec.yaml` not incremented

**Solution:**

1. Check current version:
```bash
grep version pubspec.yaml
# version: 1.0.0+10
```

2. Increment build number (the +10 part):
```bash
python .claude/skills/ayutthaya-camp-expert/scripts/bump_version.py patch
```

3. Or manually:
```yaml
version: 1.0.1+11
```

**Best practice:**
Use git commit count for build number:
```bash
git rev-list --count HEAD
```

---

### 6. iOS Certificate Expired

**Error:**
```
The provisioning profile has expired
```

**Cause:**
Apple certificates expire after 1 year

**Solution:**

1. Renew in Apple Developer Portal:
   - https://developer.apple.com/account/resources/certificates

2. Download new certificate and provisioning profile

3. Export new .p12:
   - Keychain Access → Right-click cert → Export

4. Update GitHub Secrets:
   - `APPLE_CERTIFICATES_P12`
   - `IOS_PROVISIONING_PROFILE`

5. Update `ios/ExportOptions.plist` with new profile name

---

## Email Delivery Errors

### 7. Emails Going to Spam

**Error:**
Emails from app landing in spam folder

**Cause:**
Missing or incorrect DNS records (SPF, DKIM, DMARC)

**Solution:**

1. Verify DNS records (project uses Resend):

SPF record:
```
TXT @ "v=spf1 include:resend.com ~all"
```

DKIM (provided by Resend dashboard)

DMARC:
```
TXT _dmarc "v=DMARC1; p=quarantine; rua=mailto:admin@ayutthayacamp.com"
```

2. Check sender domain:
```typescript
// functions/src/email/resendService.ts
from: 'noreply@ayutthayacamp.com' // Must use verified domain
```

3. Test delivery:
```bash
python scripts/test_notifications.py user@example.com
```

**Reference docs:**
- `SOLUCION_EMAILS_SPAM.md`
- `CONFIGURACION_DNS_FINAL.md`
- `MIGRACION_RESEND_COMPLETADA.md`

---

### 8. Email Function Failing

**Error:**
```
Function failed on loading user data: firebase-admin cannot be loaded
```

**Cause:**
Missing dependencies in Cloud Functions

**Solution:**

1. Check `functions/package.json`:
```json
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "resend": "^6.9.3"
  }
}
```

2. Reinstall:
```bash
cd functions
npm install
npm run build
```

3. Redeploy:
```bash
firebase deploy --only functions
```

---

## CI/CD Errors

### 9. GitHub Actions Failing - Secrets Missing

**Error:**
```
Error: Input required and not supplied: ANDROID_KEYSTORE_BASE64
```

**Cause:**
GitHub Secrets not configured

**Solution:**

Verify all 14 secrets exist:

**General:**
- `SONAR_TOKEN`
- `CODECOV_TOKEN` (optional)

**Android:**
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

**iOS:**
- `APP_STORE_CONNECT_API_KEY`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APPLE_CERTIFICATES_P12`
- `APPLE_CERTIFICATES_PASSWORD`
- `IOS_PROVISIONING_PROFILE`
- `APPLE_DEVELOPER_TEAM_ID`

Add in: **Settings → Secrets and variables → Actions**

---

### 10. detect-secrets Baseline Missing

**Error:**
```
.secrets.baseline not found. Generating baseline...
```

**Cause:**
First time running CI/CD

**Solution:**

1. Generate baseline:
```bash
pip install detect-secrets
detect-secrets scan --baseline .secrets.baseline
```

2. Audit (mark false positives as 'n'):
```bash
detect-secrets audit .secrets.baseline
```

3. Commit:
```bash
git add .secrets.baseline
git commit -m "Add secrets baseline"
git push
```

---

## Development Errors

### 11. Provider Not Found

**Error:**
```
Error: Could not find the correct Provider<AuthViewModel> above this Widget
```

**Cause:**
ViewModel not registered in `lib/app/app.dart`

**Solution:**

Add to providers list:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(AuthRepositoryImpl()),
    ),
    ChangeNotifierProvider(
      create: (_) => NewFeatureViewModel(NewFeatureRepositoryImpl()),
    ),
  ],
  child: MaterialApp(...),
)
```

---

### 12. Hot Reload Not Working After Provider Changes

**Error:**
Changes to ViewModels not reflecting

**Cause:**
Provider state persists across hot reloads

**Solution:**

Use hot **restart** instead:
```bash
# In terminal
r  # Hot restart
R  # Full rebuild
```

Or in IDE: Stop → Run again

---

## Data Errors

### 13. Corrupt Payment Records

**Error:**
Payments with missing or invalid fields

**Cause:**
App version mismatch or manual Firebase edits

**Solution:**

Run cleanup script:
```bash
python scripts/clean_corrupt_payment.py
```

**⚠️ Confirmation required:** Script will ask twice before deleting

---

### 14. User Account Stuck in Pending

**Error:**
User paid but account still pending

**Cause:**
Admin didn't approve payment, or payment document missing

**Debug:**

1. Check user status:
```bash
python scripts/check_user.py user@example.com
```

2. Check payments:
```
User: user@example.com
Status: pending
Payments: 1 payment(s)
  - Payment ID: xyz123
    Status: pending
    Amount: $50
```

3. Manually approve in Firebase Console or admin panel

---

## Quick Diagnosis Checklist

When something breaks:

1. **Check Firebase Console**
   - Firestore data correct?
   - Rules deployed?
   - Functions logs?

2. **Check GitHub Actions**
   - Build passing?
   - All secrets configured?

3. **Check local environment**
   - `flutter doctor`
   - `flutter pub get`
   - `.env` file exists?

4. **Check git status**
   - Uncommitted changes?
   - Wrong branch?

5. **Run quality checks**
   - `flutter analyze`
   - `flutter test`
   - `detect-secrets scan`
