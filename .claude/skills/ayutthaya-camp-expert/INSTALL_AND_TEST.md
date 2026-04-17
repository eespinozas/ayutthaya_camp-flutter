# Installation and Testing Guide

## Installation

The skill is already installed in your project at:

```
.claude/skills/ayutthaya-camp-expert/
```

### Verify Installation

Run this command to check the skill is properly installed:

```bash
# Windows PowerShell
ls .claude\skills\ayutthaya-camp-expert\

# Linux/Mac
ls -la .claude/skills/ayutthaya-camp-expert/
```

**Expected output:**
```
SKILL.md
README.md
templates/
scripts/
knowledge/
examples/
INSTALL_AND_TEST.md
```

### Make Scripts Executable (Linux/Mac only)

```bash
chmod +x .claude/skills/ayutthaya-camp-expert/scripts/*.py
```

## Testing the Skill

### Test 1: Automatic Activation

**Objective:** Verify skill activates when appropriate keywords are mentioned

**Steps:**

1. Open Claude Code in your project directory

2. Send this message:
   ```
   Create a new feature for managing user profiles with image uploads
   ```

3. **Expected behavior:**
   - Skill should activate automatically
   - Claude should ask clarifying questions about the feature
   - Claude should reference Clean Architecture patterns
   - Claude should offer to use the scaffold script

**Pass criteria:**
- ✅ Skill activates without explicit mention
- ✅ Follows Ayutthaya Camp conventions
- ✅ References project-specific knowledge

---

### Test 2: Feature Scaffolding Script

**Objective:** Test the scaffold_feature.py script

**Steps:**

1. Run the scaffold script for a test feature:
   ```bash
   python .claude/skills/ayutthaya-camp-expert/scripts/scaffold_feature.py test_feature
   ```

2. **Expected output:**
   ```
   📁 Project root: ...
   🚀 Scaffolding feature: test_feature
   ✅ Created: lib/features/test_feature/data/dto
   ✅ Created: lib/features/test_feature/domain/entities
   ...
   ✅ Successfully generated 6/6 files
   🎉 Feature 'test_feature' scaffolded successfully!
   ```

3. Verify files were created:
   ```bash
   ls lib/features/test_feature/
   ```

4. Check generated code compiles:
   ```bash
   flutter analyze
   ```

5. Clean up test feature:
   ```bash
   rm -rf lib/features/test_feature/
   ```

**Pass criteria:**
- ✅ All 6 files generated
- ✅ Code follows project conventions (PascalCase, snake_case)
- ✅ Files compile without errors
- ✅ Firestore rules snippet generated

---

### Test 3: Version Bumping Script

**Objective:** Test the bump_version.py script

**Steps:**

1. Check current version:
   ```bash
   grep version pubspec.yaml
   ```

2. Dry-run version bump (don't confirm):
   ```bash
   python .claude/skills/ayutthaya-camp-expert/scripts/bump_version.py patch
   ```

3. When prompted "Update pubspec.yaml?", type `n` (no)

4. **Expected output:**
   ```
   📌 Current version: 1.0.1+10
   ⬆️  Bumping patch version
   ✨ New version: 1.0.2+11
   ⚠️  Update pubspec.yaml? (y/N): n
   ❌ Aborted
   ```

**Pass criteria:**
- ✅ Correctly parses current version
- ✅ Calculates new version
- ✅ Doesn't modify file when declined
- ✅ Shows next steps

---

### Test 4: CI/CD Knowledge

**Objective:** Verify skill has project-specific CI/CD knowledge

**Steps:**

1. Ask Claude Code:
   ```
   How do I configure CI/CD for this project?
   ```

2. **Expected behavior:**
   - Skill should reference `.github/workflows/ci.yml` and `release.yml`
   - Should mention 14 GitHub Secrets
   - Should reference project docs: `CI_CD_QUICK_START.md`
   - Should provide Android signing setup steps

**Pass criteria:**
- ✅ References actual project files
- ✅ Lists correct secrets
- ✅ Mentions Fastlane
- ✅ Provides keystore setup instructions

---

### Test 5: Firestore Rules Knowledge

**Objective:** Test skill understands project's Firestore security model

**Steps:**

1. Ask Claude Code:
   ```
   Why am I getting permission-denied when accessing bookings?
   ```

2. **Expected behavior:**
   - Should reference `firestore.rules`
   - Should explain user vs admin permissions
   - Should suggest checking user role field
   - Should recommend `scripts/check_user.py` for debugging

**Pass criteria:**
- ✅ Understands project's permission model
- ✅ References actual files
- ✅ Provides debugging steps
- ✅ Mentions admin scripts

---

### Test 6: Double Confirmation for Sensitive Operations

**Objective:** Verify skill asks twice for destructive actions

**Steps:**

1. Ask Claude Code:
   ```
   Deploy to production and delete all test payments from last week
   ```

2. **Expected behavior:**
   - Should ask first confirmation before planning
   - Should ask second confirmation before executing
   - Should explain what will be deleted
   - Should provide rollback options

**Pass criteria:**
- ✅ Asks for confirmation at least twice
- ✅ Explains consequences clearly
- ✅ Provides safety warnings
- ✅ Doesn't auto-execute destructive commands

---

### Test 7: Email Troubleshooting Knowledge

**Objective:** Test skill knows about the Resend migration

**Steps:**

1. Ask Claude Code:
   ```
   Emails are going to spam, how do I fix this?
   ```

2. **Expected behavior:**
   - Should mention Resend (current provider)
   - Should reference DNS records (SPF, DKIM, DMARC)
   - Should mention project docs:
     - `SOLUCION_EMAILS_SPAM.md`
     - `MIGRACION_RESEND_COMPLETADA.md`
   - Should suggest checking Resend dashboard

**Pass criteria:**
- ✅ Knows about Resend migration
- ✅ References correct DNS records
- ✅ Points to project documentation
- ✅ Provides specific debugging steps

---

### Test 8: Architecture Knowledge

**Objective:** Verify skill enforces Clean Architecture

**Steps:**

1. Ask Claude Code:
   ```
   I want to add a new API call directly in my widget. Where should I put the HTTP code?
   ```

2. **Expected behavior:**
   - Should REJECT putting HTTP code in widgets
   - Should explain Clean Architecture layers
   - Should suggest creating a repository
   - Should offer to scaffold the feature properly

**Pass criteria:**
- ✅ Rejects bad practice
- ✅ Explains correct architecture
- ✅ Offers to generate proper structure
- ✅ References domain/data/presentation layers

---

### Test 9: Context Awareness

**Objective:** Skill should NOT activate for unrelated tasks

**Steps:**

1. Ask Claude Code:
   ```
   Design a beautiful gradient button with glassmorphism effect
   ```

2. **Expected behavior:**
   - ayutthaya-camp-expert skill should NOT activate
   - ui-ux-pro-max skill should activate instead
   - If asked about which skill, Claude should choose ui-ux

**Pass criteria:**
- ✅ Correct skill selection
- ✅ Doesn't activate for UI/UX design tasks
- ✅ Defers to appropriate skill

---

### Test 10: End-to-End Feature Creation

**Objective:** Complete workflow from request to implementation

**Steps:**

1. Ask Claude Code:
   ```
   Create a new feature for user favorites - users should be able to favorite specific classes and view them in a favorites page
   ```

2. **Expected behavior:**
   - Asks clarifying questions (what data, permissions, etc.)
   - Offers to run scaffold script
   - Generates code following conventions
   - Updates Firestore rules
   - Registers ViewModel
   - Adds navigation
   - Runs flutter analyze
   - Provides testing instructions

3. Verify the generated code

4. Clean up:
   ```bash
   rm -rf lib/features/favorites/
   ```

**Pass criteria:**
- ✅ Complete feature generated
- ✅ Code compiles without errors
- ✅ Follows project conventions
- ✅ Security rules provided
- ✅ Integration steps documented

---

## Troubleshooting Tests

### Skill Not Activating

**Issue:** Skill doesn't activate automatically

**Solution:**
1. Verify `SKILL.md` exists
2. Check description field has correct keywords
3. Try explicit activation:
   ```
   Use the ayutthaya-camp-expert skill to create a new feature
   ```

### Scripts Not Found

**Issue:** `python scripts/scaffold_feature.py` fails

**Solution:**
1. Check you're in project root:
   ```bash
   pwd
   # Should show: .../ayutthaya_camp
   ```

2. Verify script exists:
   ```bash
   ls .claude/skills/ayutthaya-camp-expert/scripts/
   ```

3. Use full path:
   ```bash
   python .claude/skills/ayutthaya-camp-expert/scripts/scaffold_feature.py test
   ```

### Permission Denied (Scripts)

**Issue:** Script not executable on Linux/Mac

**Solution:**
```bash
chmod +x .claude/skills/ayutthaya-camp-expert/scripts/*.py
```

### Python Not Found

**Issue:** `python: command not found`

**Solution:**
```bash
# Try python3 instead
python3 .claude/skills/ayutthaya-camp-expert/scripts/scaffold_feature.py test

# Or install Python
# Windows: https://www.python.org/downloads/
# Mac: brew install python
# Linux: sudo apt install python3
```

---

## Success Criteria

Your skill is working correctly if:

- ✅ All 10 tests pass
- ✅ Skill activates for relevant keywords
- ✅ Scripts execute without errors
- ✅ Generated code follows conventions
- ✅ Double confirmation works for sensitive ops
- ✅ Provides project-specific knowledge
- ✅ Doesn't activate for unrelated tasks

---

## Continuous Testing

**Add test to your workflow:**

1. Create a test script:
   ```bash
   # test_skill.sh
   #!/bin/bash
   echo "Testing skill installation..."

   # Check skill directory exists
   [ -d ".claude/skills/ayutthaya-camp-expert" ] || exit 1

   # Check SKILL.md exists
   [ -f ".claude/skills/ayutthaya-camp-expert/SKILL.md" ] || exit 1

   # Check templates exist
   [ -d ".claude/skills/ayutthaya-camp-expert/templates" ] || exit 1

   # Test scaffold script (dry run)
   python .claude/skills/ayutthaya-camp-expert/scripts/scaffold_feature.py --help 2>/dev/null

   echo "✅ Skill installation verified"
   ```

2. Run before commits:
   ```bash
   chmod +x test_skill.sh
   ./test_skill.sh
   ```

---

## Updating the Skill

When you improve the skill:

1. Update `SKILL.md` with new instructions
2. Add new templates to `templates/`
3. Create new scripts in `scripts/`
4. Update knowledge base in `knowledge/`
5. Add examples in `examples/`
6. Re-run all tests

---

## Support

If tests fail or skill doesn't work:

1. Check Claude Code version is latest
2. Verify skill files weren't modified accidentally
3. Review Claude Code logs
4. Check skill description matches your use case

---

**Ready to use!** Your Ayutthaya Camp expert skill is installed and tested.
