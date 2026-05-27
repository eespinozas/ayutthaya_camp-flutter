# ACMApp — iOS Deployment Guide

How to build and ship **ACMApp (Ayutthaya Camp)** to TestFlight with fastlane.

---

## 1. Overview

| Item | Value |
|---|---|
| App name (App Store) | **ACMApp** |
| Bundle ID | `com.ayutthaya.ayutthayacamp` |
| SKU | `com.ayutthaya.ayutthaya-camp` |
| Apple Team | Exequiel Espinoza — Team ID `2S96B83U6W` |
| Apple auth | App Store Connect **API key** (`.p8`) — no 2FA, no passwords |
| Signing | `fastlane match` — *App Store* type, manual signing |
| Certificates store | Private repo `github.com/eespinozas/ayutthaya-certificates` |
| Provisioning profile | `match AppStore com.ayutthaya.ayutthayacamp` |
| Version source | `pubspec.yaml` → `version: <name>+<build>` |

The whole pipeline is **non-interactive** — it authenticates with an App Store
Connect API key, so it works locally and in CI without 2FA prompts.

---

## 2. Prerequisites (one-time, per machine)

- macOS with **Xcode** + Command Line Tools
- **Flutter** SDK on `PATH`
- **fastlane** — `brew install fastlane`
- Access to the secrets file `ios/fastlane/.env` (NOT in git — see §6)
- Read access to the private certificates repo (via `gh auth login` or an
  SSH key / token for `github.com/eespinozas/ayutthaya-certificates`)

That's it. Certificates are pulled automatically from the private repo — you
never manually install anything in Xcode.

---

## 3. Releasing a new TestFlight build

From the **`ios/`** directory:

```bash
cd ios
fastlane beta
```

That single command:

1. **`match`** — syncs the Apple Distribution certificate + App Store profile
   from the private repo (read-only).
2. **Build number** — queries TestFlight for the latest build of the current
   version and uses `latest + 1` (first build is `1`). Writes it to
   `pubspec.yaml`.
3. **`flutter build ios --release`** — compiles the Dart/Flutter app.
4. **`build_app`** — archives & exports a signed `.ipa` (App Store method).
5. **`upload_to_testflight`** — uploads the build to App Store Connect.
6. **Git** — commits the `pubspec.yaml` version bump, tags it
   `ios/v<version>-<build>`, and pushes.

After it finishes, the build appears in **App Store Connect → TestFlight**
and takes ~5–15 min to finish *Processing*.

### Releasing a new version (not just a build)

Bump the version *name* in `pubspec.yaml` first, then run `fastlane beta`:

```yaml
# pubspec.yaml
version: 1.1.0+1   # change 1.0.0 -> 1.1.0; the +build is recalculated
```

```bash
cd ios && fastlane beta
```

---

## 4. Available lanes

| Lane | Purpose |
|---|---|
| `fastlane beta` | Build + upload a new TestFlight build (the normal command). |
| `fastlane certificates` | Pull signing certs/profiles (read-only). Run on a new machine. |
| `fastlane setup` | One-time: register the App ID + generate signing assets. Already done. |

---

## 5. Build number strategy

- **Version name** (`1.0.0`) → set manually in `pubspec.yaml`.
- **Build number** (`+1`, `+2`, …) → managed automatically. `fastlane beta`
  reads the highest build number on TestFlight for the current version and
  adds 1. This guarantees a unique, monotonic build number every time, even
  across multiple machines or CI — no manual tracking needed.
- `pubspec.yaml` is the single source of truth Flutter reads; fastlane keeps
  it in sync and commits the change.

> Do **not** use `increment_build_number(xcodeproj:)` — in a Flutter project
> the Xcode build number is `$(FLUTTER_BUILD_NUMBER)`, driven by `pubspec.yaml`.

---

## 6. Secrets & certificates

### `ios/fastlane/.env` (gitignored — never commit)

| Key | What it is |
|---|---|
| `ASC_KEY_ID` | App Store Connect API key ID |
| `ASC_ISSUER_ID` | App Store Connect API issuer ID |
| `ASC_KEY_FILEPATH` | Absolute path to the `.p8` API key file |
| `MATCH_PASSWORD` | Passphrase that encrypts the certificates repo |
| `KEYCHAIN_PASSWORD` | Password for the dedicated code-signing keychain (see §10) |
| `FASTLANE_USER` / `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | Fallback Apple auth (unused while the API key works) |

- The `.p8` API key lives at `ios/fastlane/AuthKey_<KEYID>.p8` — **gitignored**.
- **`MATCH_PASSWORD` must be kept in a password manager.** If it is lost, the
  certificates repo cannot be decrypted and all certs must be regenerated.
- The certificates repo `ayutthaya-certificates` must stay **private**.

### How certificates are stored

`fastlane match` keeps the Apple Distribution certificate (`.cer` + `.p12`)
and the App Store provisioning profile in the private `ayutthaya-certificates`
repo, **encrypted** with `MATCH_PASSWORD`. Any machine with `.env` + repo
access runs `fastlane certificates` to install them — no manual Xcode steps.

---

## 7. Adding TestFlight testers

TestFlight testers are managed in **App Store Connect → TestFlight**, not in
fastlane. App Store provisioning profiles do **not** need device UDIDs.

- **Internal testers** (up to 100): App Store Connect → *Users and Access*,
  then add them under TestFlight → *Internal Testing*. They get builds
  immediately, no review.
- **External testers** (up to 10,000): TestFlight → *External Testing* →
  create a group, add testers by email. The first build for external testers
  must pass a short **Beta App Review**.

> UDID device registration is only relevant for *Ad-Hoc* builds — not for
> TestFlight / App Store builds, which we use here.

---

## 8. New machine / new developer setup

```bash
brew install fastlane
gh auth login                       # access to the private certs repo
# obtain ios/fastlane/.env and the .p8 from a teammate (securely)
cd ios && fastlane certificates     # installs certs/profile locally
cd ios && fastlane beta             # ship
```

---

## 9. Rotating credentials

- **App Store Connect API key** — regenerate in App Store Connect →
  *Users and Access → Integrations*. Download the new `.p8`, update
  `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_FILEPATH` in `.env`.
- **App-specific password** — rotate every ~6 months at appleid.apple.com
  (only a fallback; the API key is the primary path).
- **Match certificates** — `cd ios && fastlane match appstore` (read-write)
  renews/regenerates. `fastlane match nuke appstore` revokes everything.

---

---

## 10. Code-signing keychain

To avoid the macOS *"codesign wants to use key …"* popup (which needs the
login keychain password), `fastlane beta` / `certificates` / `setup` use a
**dedicated keychain** — `fastlane_acmapp.keychain-db` — recreated on every
run:

- It is created/unlocked with `KEYCHAIN_PASSWORD` from `.env` (a
  fastlane-only password — **not** your macOS login password).
- `match` imports the signing certificate into it and, because it knows the
  keychain password, sets the key partition list — so `codesign` runs
  silently with no popup.
- The stale identity is removed from the login keychain so signing always
  uses this dedicated keychain.

Nothing to do manually — it is fully automated. If you ever change
`KEYCHAIN_PASSWORD`, just keep `.env` consistent.

---

See **`TROUBLESHOOTING.md`** for common errors and fixes.
