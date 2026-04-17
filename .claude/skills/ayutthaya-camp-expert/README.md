# Ayutthaya Camp Expert Skill

Expert AI assistant for the Ayutthaya Camp Flutter project.

## What This Skill Does

Provides specialized knowledge and automation for:

- **Scaffolding features** with Clean Architecture
- **CI/CD configuration** (GitHub Actions, Fastlane)
- **Release management** (versioning, TestFlight, Google Play)
- **Firebase operations** (Functions, Firestore rules, data scripts)
- **Admin tasks** (user management, payment cleanup)
- **Troubleshooting** (email delivery, permissions, signing)

## When It Activates

The skill automatically activates when you mention:

- Creating new features or modules
- Clean Architecture, ViewModels, repositories
- Firebase, Firestore rules, Cloud Functions
- CI/CD, GitHub Actions, releases
- Admin scripts, data cleanup
- Email delivery issues

## Installation

This skill is already integrated in your project at:
```
.claude/skills/ayutthaya-camp-expert/
```

Claude Code will automatically detect and use it when appropriate.

## Manual Activation

To explicitly activate the skill:

```
Use the ayutthaya-camp-expert skill to [task]
```

Example:
```
Use the ayutthaya-camp-expert skill to create a new notifications feature
```

## Key Features

### 1. Feature Scaffolding

Generates complete Clean Architecture structure:

```bash
python .claude/skills/ayutthaya-camp-expert/scripts/scaffold_feature.py notifications
```

Creates:
```
lib/features/notifications/
├── data/
│   ├── api/
│   ├── dto/
│   └── repositories/
├── domain/
│   ├── entities/
│   └── repositories/
└── presentation/
    ├── pages/
    ├── viewmodels/
    └── widgets/
```

### 2. Double Confirmation

All destructive operations require two confirmations:

- Deploy to production
- Database modifications
- User/payment deletions
- Release tags

### 3. Priority Workflows

Optimized for your top use cases:

1. Creating new features
2. CI/CD setup
3. Releases
4. Data cleanup
5. User reports
6. Email debugging

### 4. Project-Specific Knowledge

- Ayutthaya Camp architecture patterns
- Firebase setup details
- Common errors and solutions
- Email delivery quirks (Resend migration)
- CI/CD secrets configuration

## Directory Structure

```
.claude/skills/ayutthaya-camp-expert/
├── SKILL.md                    # Main prompt (this is what Claude reads)
├── README.md                   # This file
├── templates/                  # Code templates
│   ├── feature/               # Feature scaffolding templates
│   ├── firebase-rules-snippet.rules
│   └── github-workflow-template.yml
├── scripts/                    # Automation scripts
│   ├── scaffold_feature.py    # Generate features
│   ├── bump_version.py        # Version management
│   ├── validate_firebase.py   # Firebase checks
│   └── admin_helper.py        # Admin utilities
├── knowledge/                  # Project knowledge base
│   ├── architecture.md        # Architecture overview
│   ├── common-errors.md       # Known issues
│   └── conventions.md         # Coding conventions
└── examples/                   # Usage examples
    ├── scaffold-feature-example.md
    ├── release-workflow-example.md
    └── firebase-troubleshooting-example.md
```

## Usage Examples

### Create a New Feature

```
Create a new in-app notifications feature with Firebase Cloud Messaging
```

The skill will:
1. Ask clarifying questions
2. Generate Clean Architecture structure
3. Create ViewModels, pages, repositories
4. Update Firestore rules
5. Register providers
6. Run flutter analyze

### Setup CI/CD in a Fork

```
Configure CI/CD for this repo
```

The skill will:
1. Verify workflow files exist
2. Guide through Android keystore setup
3. Guide through iOS certificates
4. List all 14 GitHub Secrets needed
5. Test the pipeline

### Release a New Version

```
Release version 1.2.3 to TestFlight and Google Play internal track
```

The skill will:
1. Run pre-flight checks
2. Bump version in pubspec.yaml
3. Ask for confirmation (1st)
4. Create and push git tag
5. Ask for confirmation (2nd)
6. Monitor GitHub Actions
7. Verify uploads

### Clean Corrupt Payments

```
Clean corrupt payments from the last 7 days
```

The skill will:
1. Verify Firebase service account
2. Ask for confirmation (1st)
3. Run cleanup script
4. Ask for confirmation (2nd)
5. Verify results in console

## Templates

### Feature Template

Located at `templates/feature/`, includes:

- **Data layer:** API client, DTO, repository implementation
- **Domain layer:** Entities, repository interface
- **Presentation layer:** Page, ViewModel, widgets

Uses placeholders:
- `{{FeatureName}}` → Pascal case (e.g., Notification)
- `{{feature_name}}` → Snake case (e.g., notification)
- `{{FEATURE_NAME}}` → Upper case (e.g., NOTIFICATION)

### Firebase Rules Template

Snippet for common patterns in `firestore.rules`:

```javascript
// User can read own documents
allow read: if request.auth.uid == userId;

// Admin can read all
allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
```

## Scripts

### scaffold_feature.py

```bash
python scripts/scaffold_feature.py {feature_name}
```

Generates complete feature structure from templates.

### bump_version.py

```bash
python scripts/bump_version.py 1.2.3
```

Updates `pubspec.yaml` with new version.

### validate_firebase.py

```bash
python scripts/validate_firebase.py
```

Checks:
- Service account exists
- Firebase project configured
- Functions dependencies installed
- Firestore rules syntax

### admin_helper.py

```bash
python scripts/admin_helper.py check-user user@example.com
```

Wrapper for common admin operations.

## Knowledge Base

### architecture.md

Overview of:
- Clean Architecture implementation
- Feature organization
- Provider pattern usage
- Firebase integration

### common-errors.md

Solutions for:
- Service account not found
- Firestore permission denied
- Android keystore issues
- iOS certificate expiration
- Email spam issues
- Version code conflicts

### conventions.md

Project standards:
- File naming (snake_case)
- Class naming (PascalCase)
- Git commit format
- Feature folder structure
- Testing requirements

## Best Practices

1. **Always run flutter analyze** before committing
2. **Test locally** before pushing
3. **Backup keystores** immediately
4. **Never commit secrets**
5. **Ask for confirmation** on destructive actions
6. **Document changes** in relevant .md files

## Security

The skill enforces:

- No secrets in code
- Verification of .gitignore
- Double confirmation for sensitive ops
- Firebase service account not committed
- Keystore backup reminders

## Troubleshooting

### Skill Not Activating

Try explicit activation:
```
@ayutthaya-camp-expert create a new feature
```

### Scripts Failing

Check prerequisites:
```bash
# Python dependencies
pip install firebase-admin

# Flutter dependencies
flutter pub get

# Firebase CLI
firebase --version
```

### Templates Not Found

Verify skill directory exists:
```bash
ls -la .claude/skills/ayutthaya-camp-expert/
```

## Contributing to the Skill

To improve the skill:

1. Update `SKILL.md` for new workflows
2. Add templates in `templates/`
3. Create scripts in `scripts/`
4. Document in `knowledge/`
5. Provide examples in `examples/`

## Version

**Version:** 1.0.0
**Created:** 2026-04-10
**Project:** Ayutthaya Camp v1.0.1+10

## License

Internal use only for Ayutthaya Camp project.
