# MacroChef

A Flutter app for macro/calorie tracking and strength training, with a
voice-driven, hands-free **cooking** mode. The distinctive angle is recipes:
generate or enter a recipe, get a per-ingredient nutrition breakdown, cook it
hands-free with on-device voice, then log the result against your daily macro
targets — alongside an adaptive macro-target engine and a full training
planner/logger.

Primary target platform is **Android** (on-device voice is mobile-only);
desktop and test runs fall back to no-op speech stubs. AI can run either against
a cloud provider (with your API key) or **fully on-device** with a downloadable
model — recipe generation, macro estimates, and voice all work offline.

## Features

- **Recipes** — enter or AI-generate a recipe and get a per-ingredient
  nutrition breakdown. Foods resolve to macros via USDA → OpenFoodFacts →
  AI-estimate, with results cached locally. The breakdown (and each ingredient's
  source) is **persisted** with the recipe and recomputed only when the
  ingredients change, so reopening a recipe is instant.
- **On-device AI (offline)** — an optional **Local** LLM provider runs a
  downloadable model (Qwen2.5 1.5B) entirely on the phone via
  [flutter_gemma](https://pub.dev/packages/flutter_gemma) / MediaPipe — recipe
  generation and macro estimates with **no API key and no network**. Cloud
  providers (Claude/OpenAI/Gemini/Groq) remain available.
- **Offline nutrition pack** — an optional downloadable pack of ~8,000 USDA
  FoodData Central foods with on-device hybrid search (FTS5 keyword prefilter +
  MiniLM sentence-embedding re-rank). A confident match returns exact USDA
  macros; a miss grounds the AI estimate in the closest real foods — all fully
  offline.
- **Backup & restore** — a silent auto-backup runs on launch (rotating
  snapshots, also mirrored to the Downloads folder), plus in-app manual
  backup/restore of the whole database and a reminder when the last offsite
  backup is stale.
- **Hands-free cooking** — on-device voice (sherpa-onnx ASR/VAD/TTS) walks you
  through a recipe step by step; natural-language intents drive the cook flow.
- **Daily logging** — log foods against daily macro targets with a food-unit
  picker (grams or count/piece units), remembered last unit/portion per food,
  a frequent-foods quick-add tab, and copy-previous-day.
- **Adaptive targets** — weight log with an exponentially-smoothed trend
  weight; macro targets adapt from intake + trend-weight history. Tracks fibre
  and sodium micros.
- **Training** — a training planner and logger:
  Program → Day → Exercise templates, per-set logging with previous-session
  reference and quick +/- weight & reps steppers, a rest timer with audio +
  background notification, a barbell plate calculator, a hands-free **voice
  workout assistant**, and a research-based muscle-coverage heatmap
  (RP MEV/MAV + Schoenfeld, with fractional secondary-muscle contributions).
- **Reports & grocery** — intake/weight reporting and a grocery list.

The app shell (`lib/app.dart`) has four tabs — **Train**, **Recipes**,
**Today**, **Settings** — with a center "+" to quick-log food.

## Getting started

```bash
flutter pub get                              # install deps
flutter run                                  # run on attached device/emulator
```

On-device voice models are **not** committed to git. Fetch them before a device
run that uses voice:

```bash
bash tool/fetch_voice_models.sh              # populates assets/models/asr|tts/
```

### Choosing an AI provider

Open **Settings → AI provider** and pick one of two paths:

- **Cloud** (Claude / OpenAI / Gemini / Groq) — select the provider and model,
  then paste an API key (stored in the OS keychain via `flutter_secure_storage`).
  This is the default and needs no download.
- **Local (on-device, offline)** — select **Local**. Settings then shows a
  **download** button for the model (~1.5 GB, fetched at runtime from Hugging
  Face; no token needed). Once downloaded, all generation runs on-device with no
  network and no API key. Recommended on a phone with ≥4 GB RAM.

> **First Android build gotcha:** flutter_gemma pulls a large native footprint
> (MediaPipe / LiteRT). If your network TLS-blocks `dl.google.com` /
> `repo.maven.apache.org`, the first build fails fetching Gradle artifacts. Build
> once on an unrestricted network (e.g. a phone hotspot) to warm the Gradle
> cache; it builds offline afterwards. Do **not** work around it by overriding
> `NO_PROXY`.

## Commands

```bash
flutter test                                 # run the full suite
flutter test test/services/foo_test.dart     # run a single test file
flutter test --name "substring"              # run tests matching a name
flutter analyze                              # lint (flutter_lints ruleset)

# Code generation (drift). Required after editing lib/data/database.dart or any
# drift table — database.g.dart is generated, not hand-edited.
dart run build_runner build --delete-conflicting-outputs

dart run flutter_launcher_icons              # regenerate the Android launcher icon
```

## Architecture

State management is **Riverpod**, with all providers centralized in
`lib/state/providers.dart` — read that first; it's the dependency graph for the
whole app (database → repositories → services → LLM/speech infrastructure).

Layering, top to bottom:

- **UI** (`lib/ui/<feature>/`) — feature-grouped screens: `cooking/`,
  `recipes/`, `daily/`, `reports/`, `grocery/`, `settings/`, `training/`. The
  shell + bottom nav lives in `lib/app.dart`; data-driven tabs are kept alive in
  an `IndexedStack` and use an `isActive` flag to refresh when visible.
- **Services** (`lib/services/`) — business logic, no Flutter imports:
  `food_lookup.dart` (USDA → OpenFoodFacts → AI fallback, cached),
  `recipe_nutrition_service.dart`, `cooking_session.dart` (voice cook flow),
  `intent_parser.dart` (NL → intents via LLM), `macro_calculator.dart`
  (per-100g → per-serving), `daily_log_service.dart`, `weight_service.dart`
  (trend weight), `adaptive_macro_service.dart`.
- **Data** (`lib/data/`) — `database.dart` is the single **drift** schema.
  Access is always through repositories in `lib/data/repositories/`, never the
  DB directly from UI/services.
- **Providers** (`lib/providers/`) — pluggable integrations behind interfaces:
  - `llm/` — `LLMProvider` with claude/openai/gemini/groq **and on-device
    `local`** implementations, built by `llm_provider_factory.dart`. Kind + model
    + API key come from settings/secure-storage; never build a non-Claude client
    with a Claude model id (use `defaultModelFor(kind)`). The `local` kind builds
    without an API key and loads a downloaded model (see below).
  - `speech/` — `SpeechProvider`; `SherpaSpeechProvider` (on-device sherpa-onnx)
    on Android/iOS, `StubSpeechProvider` elsewhere.

## AI / LLM stack

The app talks to LLMs through a single `LLMProvider` interface
(`lib/providers/llm/llm_provider.dart`) with five interchangeable backends —
four cloud, one on-device — built by `llm_provider_factory.dart`:

| Provider | Kind     | Default model              | Also selectable                         |
|----------|----------|----------------------------|-----------------------------------------|
| Claude   | `claude` | `claude-haiku-4-5`         | `claude-sonnet-4-6`, `claude-opus-4-8`  |
| OpenAI   | `openai` | `gpt-4o-mini`              | `gpt-4o`                                |
| Gemini   | `gemini` | `gemini-2.0-flash`         | `gemini-2.5-flash`                      |
| Groq     | `groq`   | `llama-3.3-70b-versatile`  | `llama-3.1-8b-instant`                  |
| Local    | `local`  | `qwen2.5-1.5b`             | *(more can be added to the registry)*   |

Each **cloud** backend is a thin `dio` client over the provider's REST endpoint
(the `local` backend runs on-device instead — see below):

| Provider | Endpoint | Auth / headers |
|----------|----------|----------------|
| Claude   | `https://api.anthropic.com/v1/messages` | `x-api-key` + `anthropic-version: 2023-06-01` |
| OpenAI   | `https://api.openai.com/v1/chat/completions` | `Authorization: Bearer …` |
| Gemini   | `https://generativelanguage.googleapis.com/v1beta/models` | API key query param |
| Groq     | `https://api.groq.com/openai/v1/chat/completions` | `Authorization: Bearer …` (OpenAI-compatible) |

Requests default to `max_tokens: 1024` (override per call via `LlmOptions`). The
active provider, model, and API key are read from Settings + secure storage
(`flutter_secure_storage`) in `providers.dart`. `defaultModelFor(kind)` is the
single source of truth for the per-provider default so a client is never
constructed with another provider's model id. In tests the network is faked
(`test/providers/_fake_dio.dart`, `llm_contract_test.dart`).

Where the LLM is used (`lib/services/`):

- `recipe_generator_service.dart` — generate a full recipe from a prompt.
- `program_generator_service.dart` — generate a training program/plan.
- `food_lookup.dart` — AI macro estimate fallback when USDA/OpenFoodFacts miss,
  plus `gramsPerPiece` estimates for count units.
- `intent_parser.dart` / `workout_intent_parser.dart` — turn a spoken phrase
  into a structured cooking or workout intent.
- `cooking_session.dart` / `workout_voice_session.dart` — the hands-free voice
  state machines that consume those intents.

### On-device (Local) provider

The four cloud backends are thin `dio` clients; the fifth, **`LocalLlmProvider`**
(`lib/providers/llm/local_provider.dart`), runs inference on the phone instead of
over HTTP. It's built without an API key and lazily loads its model on first use.
Everything under `lib/providers/llm/local/`:

| File | Role |
|------|------|
| `local_models.dart` | Curated registry of downloadable models — id, display name, download URL, exact byte size, arch, and per-model `maxTokens`. |
| `local_model_manager.dart` | Resolves the on-device path (`…/models/llm/`), reports download state (not-/partial/-downloaded), and streams the download with progress. |
| `local_download_controller.dart` | Riverpod-facing download/delete state so the download survives closing the Settings sheet. |
| `flutter_gemma_engine.dart` | Real Android/iOS engine over `flutter_gemma` (MediaPipe LLM Inference) behind a `LocalEngine` seam — the desktop/test build swaps in a stub. |
| `local_prompt.dart` / `local_json.dart` | Prompt builders and a JSON extractor/repair pass (small local models emit slightly-off JSON, so output is repaired before `structured()` parses it). |

Non-obvious constraints (see [`CLAUDE.md`](CLAUDE.md) and the git log for the
full story):

- **`flutter_gemma` is pinned to `0.12.6`.** Newer releases need Dart ≥3.12 or
  add a `sqlite3 ^3.x` dep that collides with `drift_dev`'s `sqlite3 ^2.6.0`.
- **Qwen's `maxTokens` stays *below* its `ekv####` KV-cache size** (capped at
  2048 on the ekv4096 model) — requesting the full cache crashes MediaPipe in the
  decode-rollback path.
- Inference runs on the **GPU backend** (`LocalBackend.gpu`) to keep the UI
  responsive while the model generates.
- Model files (`.task`, MediaPipe format) are downloaded at runtime from public
  Hugging Face URLs (no token) — never committed to git.

## Voice stack (on-device, offline)

All speech runs **on-device** with [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx)
— no audio leaves the phone, and it works offline. Heavy inference runs on a
**background isolate** (`voice_worker.dart`) so the UI thread stays smooth; the
main isolate (`sherpa_speech_provider.dart`) only handles the mic and audio
playback.

### Models

Fetched by `tool/fetch_voice_models.sh` from the sherpa-onnx model releases (not
committed to git — ~266 MB total, so they stay out of the repo):

| Role | Model | Files (size) | Notes |
|------|-------|--------------|-------|
| **ASR** (speech → text) | Whisper `base.en`, int8-quantized | encoder 28 MB, decoder 125 MB, tokens 816 KB | offline/batch English transcription |
| **VAD** (voice detection) | Silero VAD | `silero_vad.onnx` (632 KB) | decides when speech starts/stops so we know *what* to transcribe |
| **TTS** (text → speech) | VITS `vits-ljs` | model 109 MB, lexicon 3.6 MB, tokens 4 KB | the assistant's spoken voice |

Models load by filesystem **path**, not from the asset bundle, so
`voice_assets.dart` copies them out of the bundle to app-support storage on first
run (idempotent — a file is re-copied only if missing or a different size). All
inference is `provider: 'cpu'` (no GPU/NNAPI dependency).

### Inference config (verified, `voice_worker.dart`)

- **Audio format:** PCM-16, **16 kHz**, mono; converted to normalized float32 on
  the main isolate, streamed to the worker.
- **CircularBuffer:** capacity `30 × 16000` (30 s of audio).
- **Silero VAD:** `windowSize` 512 samples, `threshold` 0.6, `minSpeechDuration`
  0.30 s, `minSilenceDuration` 0.6 s, `numThreads` 1, `bufferSizeInSeconds` 30.
  Thresholds are stricter than sherpa defaults to reject background static.
- **Whisper recognizer:** `featureDim` 80, `language` `en`, `task` `transcribe`,
  `numThreads` 2.
- **VITS TTS:** `numThreads` 2, `maxNumSentences` 1, `sid` 0, `speed` 1.0;
  synthesized to a WAV in the worker, then played on the main isolate.

### Pipeline

```
mic (record pkg)              ── PCM-16, 16 kHz, mono
  → main isolate (sherpa_speech_provider.dart): PCM-16 → float32,
    streams sample chunks to the worker isolate
  → CircularBuffer (30 s) → drained in 512-sample windows
  → Silero VAD                ── threshold 0.6, minSpeech 0.30 s,
                                 minSilence 0.6 s
  → on a completed speech segment → emit 'transcribing' (UI shows a spinner)
  → Whisper offline decode (~1–3 s, blocks the worker not the UI)
  → hallucination filter       ── drops Whisper's non-speech canned phrases
                                  ("you", "thanks for watching", ♪, [music],
                                  single chars / pure punctuation, etc.)
  → final transcript → intent parser (LLM) → cooking/workout session
  → assistant reply → VITS TTS (synthesized in the worker → WAV)
  → audioplayers plays the WAV
     (gainTransientMayDuck on Android / duckOthers+mixWithOthers on iOS —
      ducks, doesn't interrupt, other audio)
```

The worker ↔ main isolate communicate over a `SendPort` message protocol
(`init` / `audio` / `tts` / `reset` / `dispose` → `ready` / `transcribing` /
`final` / `tts` / `error`). Whisper is offline/batch, so there are **no live
partial transcripts** — the `SpeechProvider` contract treats partials as
optional. On desktop and in tests, `StubSpeechProvider` is substituted so nothing
depends on a mic or native models.

## Food lookup & macro data flow

Foods resolve to a `PerHundred` (kcal/protein/carb/fat per 100 g) via `FoodLookup`
in a three-tier cascade, with the result cached in the `FoodCache` table
(`source` = `usda` | `off` | `ai` | `manual`, plus `isEstimate` / `userOverride`
flags):

1. **USDA FoodData Central** — `https://api.nal.usda.gov/fdc/v1/foods/search`
   (requires an API key; authoritative for generic whole foods). Result is
   accepted only if it passes a plausibility check.
2. **OpenFoodFacts** — `https://world.openfoodfacts.org/cgi/search.pl` (good for
   branded/packaged products; no key).
3. **LLM estimate** — the configured `LLMProvider` estimates macros when both
   databases miss.

`MacroCalculator` scales per-100 g values to a gram quantity. Count/piece units
("2 tortillas") convert to grams via `FoodCache.gramsPerPiece` (AI-estimated,
user-adjustable).

## Data & migrations

`lib/data/database.dart` is the single **drift** schema — currently
**`schemaVersion` 13**, with **18 tables**: `Recipes`, `RecipeIngredients`,
`RecipeSteps`, `FoodCache`, `LogEntries`, `DailyTargetsTable`, `Settings`,
`GroceryItems`, `WeightEntries`, `Exercises`, `WorkoutSessions`, `SetEntries`,
`WorkoutTemplates`, `TemplateDays`, `TemplateExercises`, `ScheduleEntries`,
`DailyActivity`, `RecipeNutritionCache` (the persisted per-ingredient recipe
breakdown). Migrations use an explicit stepwise `onUpgrade`. When
adding/altering a table or column: bump `schemaVersion`, add a migration step,
then regenerate with build_runner. Migration tests guard upgrade behavior.

## Backup & restore

The whole database is one SQLite file (`macrochef.sqlite`), so backup is a file
copy. `lib/services/backup_service.dart` (pure, path-based `BackupIO` + a
plugin-facing wrapper) and `lib/services/auto_backup.dart` (policy) provide:

- **Silent auto-backup on launch** — at most once every 12 h, keeping the last 5
  rotating snapshots both in app storage and mirrored to the device **Downloads**
  folder (via a MediaStore channel in `shared_storage.dart`).
- **Reinstall recovery** — bootstrap discovers the newest valid timestamped
  backup in `Downloads/MacroChef`. Empty or unchanged seed-only installs recover
  automatically; meaningful current data always requires confirmation. Android
  may request file access, and deleting a consumed pre-reinstall backup may need
  a separate system prompt.
- **Manual backup / restore** from Settings. A restore is validated (the file
  must begin with the SQLite magic header) and **staged** as `macrochef.import.sqlite`,
  then swapped in on next launch so nothing writes the live DB mid-session.
- **Manual recovery retry** — Settings → Backup & Restore → **Recover latest
  automatic backup** retries discovery/access and stages recovery; it always
  asks before replacing active data.
- **Stale-backup reminder** — nudges for an offsite (e.g. Drive) backup once the
  last one is older than 7 days.

After recovery, MacroChef first creates and verifies a fresh timestamped backup
owned by the current installation. Only then does it offer to delete the
consumed source; old-install Downloads files cannot always be silently removed.

Release builds use a **stable signing keystore** so app updates and restores keep
the existing app-data sandbox instead of wiping it. Keystore backup and the
in-app backup/restore flow are documented in the dev runbook under `docs/`.

## Testing

**60 test files** with **~364 `test`/`testWidgets` cases** live in `test/`,
mirroring `lib/` (`services/`, `data/`, `providers/`, `ui/`, `integration/`). LLM
and HTTP are faked (`test/providers/_fake_dio.dart`, `llm_contract_test.dart`);
drift uses an in-memory executor. Prefer service-level tests over widget tests
for logic.

## Platform / Android

- **minSdk 24** (raised from 23 for `flutter_gemma`), **compileSdk 36**, **NDK
  `27.0.12077973`** (required by `flutter_secure_storage` / `sherpa_onnx`),
  **Android Gradle Plugin 8.9.1** (required by `flutter_gemma`'s transitive
  `androidx.core:1.17.0`).
- **Permissions** (`AndroidManifest.xml`): `RECORD_AUDIO` (voice), `INTERNET`
  (LLM + food APIs), `CAMERA` (food photos), and for the rest timer
  `POST_NOTIFICATIONS`, `VIBRATE`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`,
  `RECEIVE_BOOT_COMPLETED`.
- App is pinned to portrait; the adaptive launcher icon uses an aubergine
  background (`#15101A`) with a transparent chef-hat foreground.

## Conventions

- Commit messages follow conventional commits (`feat:`, `fix:`, `refactor:` …);
  attribution trailers are disabled.
- The theme is a custom dark "glass" aesthetic in `lib/theme/` and
  `lib/ui/widgets/glass_panel.dart` — reuse these rather than ad-hoc colors.

See [`CLAUDE.md`](CLAUDE.md) for the full developer guide and environment
gotchas (e.g. don't override `NO_PROXY`; `fl_chart` and `drift` are pinned).
