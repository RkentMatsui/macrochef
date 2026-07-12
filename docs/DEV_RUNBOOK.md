# Dev Runbook — running without wiping your data

## Why data gets wiped on `flutter run`

`flutter run` defaults to a **debug** build, signed with the **debug** keystore.
Your real data lives in whatever install currently holds it — and if that install
was signed with a **different** key (e.g. a **release** build from your stable
keystore), Android refuses the in-place update, so Flutter **uninstalls then
reinstalls**. Uninstall clears app-private storage, taking the drift database
(`macrochef.sqlite`) with it.

**The wipe is caused by *switching signatures*, not by running per se.** Debug →
release, or release → debug, on the same device = wipe. Staying on one signature =
data persists.

## The three habits (do all three)

### 1. Match the signature — run the same build type your data lives in
- Data is in the **release** install → run `flutter run --release` (release-signed,
  updates in place, no wipe). Needs `android/key.properties` present (it is).
- Data is in a **debug** install → plain `flutter run` is fine; just never switch
  that device to a release build without exporting first.
- **Rule of thumb:** pick ONE build type for the phone that holds real data and
  stick to it.

### 2. Use the hot-reload dev loop to avoid reinstalls between edits
`tool/dev_supervisor.dart` owns a `flutter run --machine` daemon and hot-reloads
when a trigger file is touched — no reinstall per edit, so no wipe across
iterations.

```bash
# start it (deviceId, trigger file)
dart run tool/dev_supervisor.dart <deviceId> /tmp/mc_reload_trigger
# from any shell, force a hot reload:
touch /tmp/mc_reload_trigger
```

> ⚠️ Caveat the code makes clear: the supervisor launches a **debug** daemon, so
> its *first* attach over a *release* install will still wipe (that's the initial
> install, a signature switch). Hot-reload only protects you from the
> reinstall-per-edit wipes *after* you're attached. So: get onto one signature
> first (habit 1), then iterate with the supervisor.

### 3. Export a backup before anything risky
Settings → **Backup & Restore** → **Export backup** → save to **Drive/Files**
(outside app storage). Then a wipe is a shrug — Import it back.

## Safety net (automatic, now built in)

On launch (throttled to ~once/12h) the app writes timestamped snapshots to a
rotating on-device folder and to **public Downloads/MacroChef/** through
MediaStore. Each location retains the newest five backups. Downloads survives an
uninstall, but Android may ask for file access after reinstall because the old
installation owned those MediaStore entries.

On the first launch after reinstall, bootstrap searches for the newest valid
Downloads backup before the normal database opens:

- Empty or unchanged seed-only local data is recovered automatically.
- Meaningful or ambiguous local data shows a confirmation with **Keep current
  data** and **Restore backup**. Recovery never silently overwrites user data.
- If Android denies direct access, use the focused system file picker when it is
  offered. Cancelling or selecting an invalid file leaves current data intact.

Recovery stages the validated file for the next launch; it never replaces the
database while Settings has it open. After the restore is verified, MacroChef
creates and verifies a fresh timestamped Downloads backup owned by the current
install. Only after that succeeds may the consumed source be deleted. Android
can require a separate delete-consent prompt, and backups owned by an old install
cannot always be silently removed.

If first-launch recovery was skipped, declined, or lost file access, open
Settings → **Backup & Restore** → **Recover latest automatic backup**. This
manual retry always asks for confirmation because it replaces an active
database, then shows the same close-and-reopen instruction as manual import.

Settings also reminds you when the last offsite **Drive/Files** export is over a
week old. Keep using **Export backup** before any risky install/signature change;
an independently readable offsite backup is the final safety net.

> The Downloads recovery, access, and delete prompts are Android-only and need a
> real-device release smoke test. Never uninstall until a manual safety backup
> has been exported and verified readable.
