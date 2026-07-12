# Release signing & data backup

This app stores **all user data in a local SQLite database on the device**
(`macrochef.sqlite` in the app documents dir, via drift). There is no server or
account. Two mechanisms protect that data across installs and devices — read
this before touching signing or reinstalling on a real phone.

---

## 1. Why stable release signing matters

Android only lets an installed app be **updated in place** when the new APK is
signed with the **same key** as the installed one. If the signing key differs,
Android forces an **uninstall-before-install** — and uninstalling **deletes the
app's private storage, including the database**. That is exactly how a real
user's data was once wiped: a release build signed with a *different* debug key
than the app already on the phone.

The fix: a **single stable release keystore**, used for every release build, on
every machine. Same key every time → installs update in place → data survives.

## 2. The signing files (git-ignored — never commit)

| File | Purpose |
|------|---------|
| `android/app/macrochef-release.jks` | The release keystore (private key). |
| `android/key.properties` | Store/key passwords, alias, and keystore filename. |

Both are listed in `.gitignore` (`*.jks`, `*.keystore`, `/android/key.properties`).
**They exist only on the machine that generated them.** They are *not* in git and
cannot be regenerated identically.

`android/app/build.gradle.kts` loads `key.properties` and signs the `release`
build type with it. When the file is absent (fresh clone, CI without secrets),
it **falls back to debug signing** so the project still builds — but a build
produced that way is a *different* signature and will force a wipe if installed
over a keystore-signed build.

### Certificate fingerprint (public — safe to share)

Use this to verify an APK was signed with the real release key:

```
CN=MacroChef, OU=Mobile, O=MacroChef
SHA-256: B5:20:51:42:0A:87:38:0C:43:00:47:1C:0E:E5:69:49:8D:7E:2F:12:74:B4:A8:F0:7F:4F:9E:68:B2:B7:72:3D
```

Verify a built APK:

```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
# The SHA256 must match the fingerprint above.
```

## 3. BACK UP THE KEYSTORE

> ⚠️ **If `macrochef-release.jks` + `key.properties` are lost, you cannot sign a
> matching update ever again** — the next install would force one more full data
> wipe, and a Play Store listing (if ever published) could never be updated.

Copy **both files** somewhere durable and private:

- a password manager (attach the `.jks`, store the passwords), and/or
- an encrypted/private cloud folder (NOT a public repo, NOT an issue/PR).

Keep the passwords out of git, chat logs, and screenshots.

### If the keystore is ever lost

You must generate a new one (this is a one-time forced wipe for existing
installs):

```bash
keytool -genkeypair -v \
  -keystore android/app/macrochef-release.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=MacroChef, OU=Mobile, O=MacroChef, L=City, ST=State, C=US"
```

Then recreate `android/key.properties`:

```properties
storePassword=<the store password you chose>
keyPassword=<the key password you chose>
keyAlias=upload
storeFile=macrochef-release.jks
```

(`storeFile` is resolved relative to `android/app/`.)

## 4. Installing on a device without wiping

- **Always** build/install **release** on a real phone (`flutter install --release`
  or `flutter run --release`) so it's signed with the stable key. A one-off
  `flutter run` **debug** build has a different signature and will force a wipe
  the next time you switch back to release.
- The first switch from an old (debug-signed) install to this keystore is the
  **last** forced wipe; after that, releases update in place.
- Xiaomi/MIUI note: ADB installs can fail with
  `INSTALL_FAILED_USER_RESTRICTED`. Enable **Developer options → Install via USB**
  (may require a Mi account + SIM) and **USB debugging (Security settings)**, keep
  the phone unlocked, and accept any on-device prompt. Fallback: hand the user
  the APK to sideload directly.

---

## 5. In-app backup & restore (defense in depth)

Even with stable signing, a factory reset or a new phone would still lose the
local DB. So the app ships an explicit backup path: **Settings → Backup &
Restore**.

- **Export** — checkpoints the WAL, copies `macrochef.sqlite` to a timestamped
  snapshot, and opens the OS share sheet so the user saves it **off-device**
  (Drive/Files). Surviving the sandbox is the point — an app-private copy would
  die with an uninstall.
- **Import** — the picked file is validated (SQLite magic header) and copied to a
  staging path (`macrochef.import.sqlite`). It is **not** applied live (the DB
  connection is open). On the next launch, `main()` calls
  `BackupService.applyPendingRestore()` **before** the database opens, which
  swaps the staged file in and deletes stale `-wal`/`-shm` sidecars.

Code: `lib/services/backup_service.dart` (pure file ops in `BackupIO` are
unit-tested in `test/services/backup_service_test.dart`); wired via
`backupServiceProvider` in `lib/state/providers.dart`; startup hook in
`lib/main.dart`.

**Cross-version caveat:** importing a snapshot from a *newer* schema into an
older app binary can fail to open (drift can't downgrade). Restore into the same
or a newer app version.
