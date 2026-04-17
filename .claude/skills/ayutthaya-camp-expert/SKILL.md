---
name: ayutthaya-camp-expert
description: |
  Expert assistant for Ayutthaya Camp Flutter app development.

  ACTIVATE when user mentions:
  - Creating/scaffolding new features or modules
  - Clean Architecture patterns, ViewModels, repositories
  - Firebase setup, Firestore rules, Cloud Functions deployment
  - CI/CD configuration, GitHub Actions, Fastlane
  - Versioning, releases, TestFlight, Google Play deployment
  - Admin scripts (Python), data cleanup, user management
  - Email delivery issues, transactional emails
  - Android signing, iOS certificates

  DO NOT ACTIVATE for:
  - General Flutter questions unrelated to this project
  - UI/UX design (use ui-ux-pro-max skill instead)
  - Generic Firebase questions (only activate for THIS project's specific setup)
---

# Ayutthaya Camp Expert Skill

You are an expert in the Ayutthaya Camp Flutter project. This skill provides specialized knowledge and automation for this specific codebase.

## Core Principles

1. **Clean Architecture First**: Always follow data/domain/presentation separation
2. **Provider Pattern**: Use ChangeNotifier ViewModels for state management
3. **Double Confirmation**: Ask twice before destructive actions (deploy prod, delete data, modify database)
4. **Security Conscious**: Never commit secrets, always validate .gitignore
5. **Test Before Deploy**: Run `flutter analyze` and `flutter test` before releases

## Project Structure Quick Reference

```
lib/features/{feature_name}/
├── data/
│   ├── api/              # HTTP clients, Firebase calls
│   ├── dto/              # Data transfer objects
│   └── repositories/     # Repository implementations
├── domain/
│   ├── entities/         # Business entities
│   └── repositories/     # Repository interfaces
└── presentation/
    ├── pages/            # UI screens
    ├── viewmodels/       # Provider ViewModels
    └── widgets/          # Feature-specific widgets
```

## Task Workflows

### 1. Creating New Features (Priority #1)

When user requests: "Create a new feature for [X]"

**Steps:**

1. **Understand requirements**
   - Ask clarifying questions about the feature
   - Identify what Firebase collections are needed
   - Determine if it needs admin or user permissions

2. **Generate scaffold**
   - Use `scripts/scaffold_feature.py {feature_name}` to create structure
   - Or manually create folders following Clean Architecture
   - Reference `templates/feature/` for boilerplate

3. **Implement layers (bottom-up)**
   - **Domain first**: Create entities (e.g., `Notification` class)
   - **Data layer**: Create DTOs, API clients, repository impl
   - **Presentation**: Create page, ViewModel, widgets

4. **Integration**
   - Register ViewModel in `lib/app/app.dart` with MultiProvider
   - Add navigation route if needed
   - Update Firestore rules in `firestore.rules`

5. **Verify**
   - Run `flutter analyze`
   - Run `flutter test` (create unit tests for ViewModel)
   - Test manually with `flutter run`

**Example command:**
```bash
python .claude/skills/ayutthaya-camp-expert/scripts/scaffold_feature.py notifications
```

**Reference:** `examples/scaffold-feature-example.md`

---

### 2. CI/CD Configuration (Priority #2)

When user requests: "Configure CI/CD" or "Setup GitHub Actions"

**Steps:**

1. **Verify prerequisites**
   - Check if `.github/workflows/ci.yml` and `release.yml` exist
   - Validate `.secrets.baseline` is committed
   - Check `sonar-project.properties` configuration

2. **Android signing setup**
   - Run `scripts/setup_android_signing.sh` (or .ps1 on Windows)
   - Guide user through keystore creation
   - Generate base64 for GitHub Secrets
   - **CRITICAL**: Remind user to backup keystore securely

3. **iOS signing setup**
   - Guide through App Store Connect API key setup
   - Help export certificates (.p12)
   - Create provisioning profile base64
   - Update `ios/ExportOptions.plist`

4. **GitHub Secrets configuration**
   - List all 14 required secrets (see `knowledge/conventions.md`)
   - Provide exact values for each secret
   - Verify secrets are set correctly

5. **Test pipeline**
   - Create test PR: `git checkout -b test/ci && git push`
   - Monitor GitHub Actions for failures
   - Fix any issues

**Reference:** Project's `CI_CD_QUICK_START.md` and `SIGNING_SETUP.md`

**Double Confirmation Required:** Before pushing tags or deploying to stores

---

### 3. Release to Stores (Priority #3)

When user requests: "Release v1.2.3" or "Deploy to TestFlight"

**Steps:**

1. **Pre-flight checks**
   - Verify all tests pass: `flutter test`
   - Check code quality: `flutter analyze --fatal-warnings`
   - Confirm CHANGELOG is updated
   - Review git status (no uncommitted changes)

2. **Bump version**
   - Use `python .claude/skills/ayutthaya-camp-expert/scripts/bump_version.py {version}`
   - Or manually edit `pubspec.yaml` version
   - Verify version format: `X.Y.Z+BUILD_NUMBER`

3. **⚠️ CONFIRMATION #1**
   - Ask: "Ready to create release tag v{version}? This will trigger CI/CD pipeline."
   - Wait for explicit YES

4. **Create and push tag**
   ```bash
   git add pubspec.yaml
   git commit -m "Bump version to {version}"
   git tag -a v{version} -m "Release v{version}"
   git push origin main
   git push origin v{version}
   ```

5. **⚠️ CONFIRMATION #2**
   - Ask: "Tag pushed. GitHub Actions will build and deploy. Continue monitoring?"
   - If YES: Monitor GitHub Actions workflow
   - If NO: Remind user to check manually

6. **Monitor deployment**
   - Check GitHub Actions for build status
   - Verify AAB uploaded to Google Play Console
   - Verify IPA uploaded to TestFlight
   - Check for any signing errors

7. **Post-deploy**
   - Test app from TestFlight/Internal track
   - Update release notes in stores (if needed)
   - Notify team

**Reference:** `examples/release-workflow-example.md`

**Double Confirmation:** Yes (steps 3 and 5)

---

### 4. Admin Scripts & Data Cleanup (Priority #4)

When user requests: "Clean corrupt payments" or "Check user status"

**Available scripts:**
- `scripts/check_user.py {email}` - Debug user account
- `scripts/check_users_status.py` - Report all users status
- `scripts/clean_corrupt_payment.py` - Remove invalid payments
- `scripts/cancel_bookings.py {user_id}` - Cancel user bookings
- `scripts/add_searchkey_to_users.py` - Add search keys to users
- `scripts/update_user_plan.py {user_id} {plan_id}` - Change user plan

**Steps:**

1. **Verify Firebase service account**
   - Check if `FIREBASE_SERVICE_ACCOUNT` env var is set
   - Or if `scripts/firebase-service-account.json` exists
   - If not, guide user to download from Firebase Console

2. **⚠️ CONFIRMATION #1**
   - Explain what the script will do
   - Ask: "This will modify production data. Confirm script: {script_name} with args: {args}?"
   - Wait for explicit YES

3. **Run script**
   ```bash
   cd scripts
   python {script_name}.py {args}
   ```

4. **⚠️ CONFIRMATION #2**
   - Show script output
   - Ask: "Script completed. Verify results in Firebase Console?"
   - If YES: Provide Firebase Console link

5. **Verify results**
   - Check Firestore console for changes
   - Run verification script if available (e.g., `check_users_status.py`)

**Reference:** `scripts/README.md`

**Double Confirmation:** Yes (steps 2 and 4)

---

### 5. User Reports & Analytics (Priority #5)

When user requests: "Generate report of active users" or "Show payment stats"

**Steps:**

1. **Understand requirements**
   - What data? (users, payments, bookings, classes)
   - Time range? (last 7 days, month, all time)
   - Format? (JSON, CSV, markdown table)

2. **Query Firestore**
   - Use Firebase Admin SDK via Python script
   - Reference existing scripts in `scripts/` for patterns
   - Example:
   ```python
   import firebase_admin
   from firebase_admin import firestore

   db = firestore.client()
   users = db.collection('users').where('status', '==', 'active').stream()
   ```

3. **Generate report**
   - Format data as requested
   - Include summary statistics
   - Add visualizations if helpful (markdown tables, charts)

4. **Save output**
   - Offer to save to file (e.g., `reports/active_users_2026-04-10.md`)
   - Or display inline if small

**Reference:** `scripts/check_users_status.py` for example queries

---

### 6. Email Delivery Debugging (Priority #6)

When user requests: "Why are emails going to spam?" or "Test email delivery"

**Steps:**

1. **Check current provider**
   - Project uses **Resend** (migrated from SendGrid)
   - Verify `functions/src/email/resendService.ts` is configured
   - Check Resend API key in Firebase Functions config

2. **Common issues (from project history)**
   - **DMARC failures**: Check DNS records (SPF, DKIM, DMARC)
   - **From address**: Must use verified domain (ayutthayacamp.com)
   - **Template formatting**: Verify HTML templates in `functions/src/email/`
   - **Rate limits**: Check Resend dashboard

3. **Test email**
   ```bash
   cd scripts
   python test_notifications.py {email_address}
   ```

4. **Verify DNS records**
   - SPF: `v=spf1 include:resend.com ~all`
   - DKIM: Verify in Resend dashboard
   - DMARC: `v=DMARC1; p=quarantine; ...`

5. **Check logs**
   - Firebase Functions logs: `firebase functions:log`
   - Resend dashboard: Check delivery status
   - User's spam folder: Test with Gmail, Outlook

**Reference:** Project's extensive email docs:
- `SOLUCION_EMAILS_SPAM.md`
- `MIGRACION_RESEND_COMPLETADA.md`
- `CONFIGURACION_DNS_FINAL.md`

---

## Firebase Operations

### Deploying Cloud Functions

```bash
cd functions
npm run build
npm run deploy
```

**⚠️ CONFIRMATION**: Ask before deploying to production environment

### Updating Firestore Rules

1. Edit `firestore.rules`
2. Test locally: `firebase emulators:start`
3. Deploy: `firebase deploy --only firestore:rules`

**⚠️ CONFIRMATION**: Ask before deploying rules (can break app access)

### Seeding Data

```bash
python scripts/seed_firebase.py    # Plans + schedules
python scripts/seed_config.py      # App configuration
```

---

## Common Gotchas (from exploration)

### 1. Firebase Service Account Missing
**Error:** `No se encontró el archivo: scripts/firebase-service-account.json`

**Solution:**
```bash
# Set environment variable
export FIREBASE_SERVICE_ACCOUNT=/path/to/service-account.json
# Or place file in: scripts/firebase-service-account.json
```

### 2. Android Keystore Backup
**Error:** Lost keystore, can't update app

**Prevention:**
- Backup `android/app/upload-keystore.jks` immediately after creation
- Store in 3 places: cloud, password manager, external drive
- Add to team's secure storage

### 3. Firestore Permission Denied
**Error:** `permission-denied` when accessing collections

**Solution:**
- Check `firestore.rules` for user role
- Verify user document has correct `role` field ('admin' or 'user')
- Use `scripts/check_user.py {email}` to debug

### 4. Version Code Conflicts
**Error:** Version code already exists in Play Console

**Solution:**
- Version code MUST increment
- Formula: `git rev-list --count HEAD` (automatic in CI/CD)
- Manual: Increase `+BUILD_NUMBER` in pubspec.yaml

### 5. iOS Certificates Expired
**Error:** Provisioning profile expired

**Solution:**
- Certificates expire yearly
- Renew in Apple Developer portal
- Re-export .p12 and update GitHub Secrets
- Update `IOS_PROVISIONING_PROFILE` secret

---

## Knowledge Base References

- **Architecture details:** `knowledge/architecture.md`
- **Common errors:** `knowledge/common-errors.md`
- **Project conventions:** `knowledge/conventions.md`

---

## Templates Usage

### Scaffold a new feature manually:

```bash
# Create folders
mkdir -p lib/features/notifications/{data,domain,presentation}/{api,dto,repositories,entities,pages,viewmodels,widgets}

# Copy templates
cp templates/feature/presentation/viewmodels/viewmodel_template.dart \
   lib/features/notifications/presentation/viewmodels/notification_viewmodel.dart

# Replace {{FeatureName}} with Notification
# Replace {{feature_name}} with notification
```

### Use scaffold script (recommended):

```bash
python .claude/skills/ayutthaya-camp-expert/scripts/scaffold_feature.py notifications
```

---

## Security Checklist

Before ANY operation:

- [ ] Check `.gitignore` includes sensitive files
- [ ] Verify no secrets in code (use `detect-secrets scan`)
- [ ] Firebase service account NOT in git
- [ ] Android keystore NOT in git
- [ ] `.env` files NOT in git

---

## Success Criteria

After completing a task, verify:

1. **Code quality:** `flutter analyze` passes with no warnings
2. **Tests:** `flutter test` passes (or new tests added)
3. **Format:** `dart format .` applied
4. **Git:** Changes committed with clear message
5. **Docs:** README or relevant .md updated if needed
6. **Security:** No secrets committed (run `detect-secrets scan`)

---

## Emergency Contacts

If something breaks in production:

1. Check Firebase Console for errors
2. Review Cloud Functions logs: `firebase functions:log`
3. Check GitHub Actions for failed pipelines
4. Rollback if needed: Use Google Play Console or TestFlight to halt rollout
5. Consult project's 50+ .md docs for specific issues

---

**Remember:** This skill is for the Ayutthaya Camp project specifically. For general Flutter help, do not activate this skill.
