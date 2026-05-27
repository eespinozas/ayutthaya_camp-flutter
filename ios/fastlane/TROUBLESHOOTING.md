# ACMApp — iOS Deployment Troubleshooting

Common errors when running `fastlane beta` / `setup` / `match`, and how to fix
them. See `DEPLOYMENT.md` for the normal workflow.

---

## Authentication

### `Missing password for user … and running in non-interactive shell`
fastlane tried to use Apple ID + password auth, which needs interactive 2FA.
- **Cause:** an action fell back to legacy auth instead of the API key.
- **Fix:** ensure `ios/fastlane/.env` has `ASC_KEY_ID`, `ASC_ISSUER_ID`,
  `ASC_KEY_FILEPATH` and that the `.p8` file exists at that path. Every lane
  calls `asc_api_key` first, which sets the API key globally.

### `produce` asks for a password / fails on "Developer Center"
Apple's **App Store Connect API does not support `produce`'s Developer Center
step** — it always wants an interactive password.
- **Fix:** we don't use `produce`. The `setup` lane registers the App ID via
  the ConnectAPI directly. The App Store Connect **app record** must be
  created **manually** once in the web UI (the API forbids `POST /v1/apps`).

### API key expired / invalid
- Regenerate at App Store Connect → *Users and Access → Integrations*,
  download the new `.p8`, and update the `ASC_*` values in `.env`.

---

## App Store Connect record

### `Could not find an app on App Store Connect with app_identifier: …`
The app record doesn't exist, or was created with the **wrong bundle ID**.
- Run `fastlane diagnose` — it lists every app + bundle ID the key can see.
- The app record's bundle ID must be **exactly** `com.ayutthaya.ayutthayacamp`
  (no hyphen). A bundle ID **cannot be changed** after the app is created —
  delete the wrong record (App Information → Delete App) and recreate it.
- New app records can take a few minutes to appear via the API.

---

## Code signing

### macOS popup: "codesign wants to use key … in your keychain"
This should no longer happen — the lanes use a **dedicated signing keychain**
(`fastlane_acmapp.keychain-db`) so `codesign` never touches the login keychain.
If a popup still appears:
- Make sure `KEYCHAIN_PASSWORD` is set in `ios/fastlane/.env`.
- The lane recreates the keychain every run; check that `prepare_signing_keychain`
  ran (look for "Dedicated signing keychain ready" in the log).
- Stale copy in the login keychain: the lane deletes it automatically, but you
  can remove it manually from **Keychain Access → login → My Certificates**.

### "errSecInternalComponent" / signing fails in the dedicated keychain
- The keychain may be locked. The lane unlocks it; if running steps manually:
  `security unlock-keychain -p "$KEYCHAIN_PASSWORD" fastlane_acmapp.keychain-db`
- Ensure it is in the search list:
  `security list-keychains -d user -s fastlane_acmapp.keychain-db login.keychain-db`

### `No profiles for 'com.ayutthaya.ayutthayacamp' were found`
The provisioning profile isn't installed locally.
- Run `cd ios && fastlane certificates` to pull it from the match repo.

### `Code signing is required for product type 'Application'` / wrong identity
- Verify the **Runner → Release** config: `CODE_SIGN_STYLE = Manual`,
  `DEVELOPMENT_TEAM = 2S96B83U6W`, `CODE_SIGN_IDENTITY = Apple Distribution`,
  `PROVISIONING_PROFILE_SPECIFIER = match AppStore com.ayutthaya.ayutthayacamp`.
- Re-apply with:
  ```bash
  cd ios && fastlane run update_code_signing_settings \
    path:"Runner.xcodeproj" use_automatic_signing:false team_id:"2S96B83U6W" \
    code_sign_identity:"Apple Distribution" \
    profile_name:"match AppStore com.ayutthaya.ayutthayacamp" \
    bundle_identifier:"com.ayutthaya.ayutthayacamp" \
    targets:"Runner" build_configurations:"Release"
  ```

### match: `Could not decrypt the repo`
Wrong `MATCH_PASSWORD`. Restore the correct passphrase in `.env` from your
password manager. If truly lost: `fastlane match nuke appstore` then
`fastlane match appstore` to regenerate everything (re-pick the passphrase).

---

## Build

### Flutter / Xcode build fails
```bash
cd /Users/eespinoza/Proyectos/flutter/ayutthaya_camp-flutter
flutter clean && flutter pub get
cd ios && pod install --repo-update
flutter doctor          # check the toolchain
```
- Delete derived data if it's stale:
  `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Build number / version is wrong
- `version:` in `pubspec.yaml` is the source of truth.
- `fastlane beta` overwrites the `+build` part with `TestFlight latest + 1`.
- To force a specific number, edit `pubspec.yaml` and run
  `flutter build ios --release --build-number=<n>`.

---

## Upload to TestFlight

### Upload fails / `Invalid binary`
- Confirm the IPA bundle ID matches the App Store Connect app record.
- Check App Store Connect → TestFlight for the rejection reason
  (missing export compliance, icon issues, etc.).

### Build stuck in "Processing"
- Normal for 5–15 min. If it's stuck for hours, re-upload a new build
  (bump happens automatically).

### Export compliance prompt
- Set it once in App Store Connect, or add to `Info.plist`:
  `ITSAppUsesNonExemptEncryption = NO` (if the app uses no custom crypto).

---

## Git

### `fastlane beta` git step fails
The lane commits only `pubspec.yaml`, tags `ios/v<version>-<build>`, and
pushes. These steps are non-fatal (`|| true`) — a failure here does **not**
fail the release. Resolve git state manually and re-tag if needed.

---

## Useful commands

```bash
cd ios
fastlane diagnose                 # list apps + bundle IDs the API key sees
fastlane certificates             # install signing assets (read-only)
fastlane match appstore           # regenerate/renew certs (read-write)
fastlane env                      # dump the fastlane environment for bug reports
```
