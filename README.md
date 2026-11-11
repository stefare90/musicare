# 🎵 MusicAre
<p align="center">
  <img src="assets/images/readme_header.png" alt="MusicAre Header" width="100%">
</p>

> Music are the plugins. We are the player.

`MusicAre` is an extensible, flexible, and lightweight music playback application. The core concept is straightforward: **the host application handles the visual user interface, navigation, track queue, and native audio playback, while all music metadata (tracks, albums, artists, search, playlists) and audio streams are provided by dynamic, hot-swappable external plugins.**

The application supports two distinct plugins:
* **Metadata Plugins**: Written in 100% Pure-Python, packaged as `.zip` archives, and loaded at runtime into the embedded CPython daemon, which the host drives over a versioned JSON wire protocol (`musicare_metadata_host_sdk`).
* **Audio Source Plugins**: Written in 100% Pure-Python, packaged as `.zip` archives, and loaded at runtime into the same embedded CPython daemon (`serious_python` + `musicare_audio_host_sdk`) for two-tier candidate search and just-in-time stream resolution.

---

## ✨ Current Features

* **Dynamic Onboarding Wizard**: Effortlessly discover, download, and configure your preferred Metadata and Audio Source plugins straight from GitHub releases.
* **Universal Media Player**: Native background playback support (`audio_service`) with a notification, lock-screen controls and hardware media key bindings.
* **Smart Queue Management**: Advanced immutable queue system supporting shuffle (preserving history), repeat modes (One, All, Off), and dynamic inserts. Playing from a partially loaded list keeps loading the rest in the background, with loading and retry states in the queue sheet.
* **Infinite Radio**: *Start radio* from any track's options replaces the queue with the seed plus a provider-generated radio batch (ListenBrainz `lb-radio`, requires sign-in). When the provider has no similar tracks, the current queue is left untouched and the app says so. With the persisted *Infinite music* switch (Settings → Playback, on by default) the queue keeps extending from the last played track when it ends — chained batch after batch and de-duplicated against the queue; signed-out playback simply stops at the end.
* **Listening History**: the app decides when a listen counts (time actually played, not the position) and shares it with the signed-in metadata provider's account history (ListenBrainz today): `playing_now` when a track starts and again after a pause longer than five seconds, and a `single` at half the track or four minutes (the first to arrive; tracks shorter than 30 s never count), with `listened_at` at the start instant and no duplicates per (track, start). There is no separate switch: sharing follows the account you signed in with. Delivery is best-effort and never blocks or interrupts playback, and a provider that keeps no listen history is detected on the first event and switched off for that plugin.
* **Fault-Tolerant Streaming**: Automatic candidate resolution—if a stream URL expires or returns a 403 Forbidden, the player automatically falls back to the next available stream. When a track cannot be resolved at all (no candidates, no stream, or a `not_found` from the audio plugin) the failure is still reported and playback advances to the next queue track, bounded to one pass over the queue (also with repeat-all); transient errors (rate limit, transport) keep the current track.
* **Global Search & Filter Chips**: Integrated with the active Metadata plugin (`ISearch`), supporting debounced queries, aggregated search views, category pagination, and instant track playback.
* **Settings, Plugin Management & Accounts**: A settings hub (gear on the three root screens) with an Appearance section (system/light/dark theme, accent color and an absolute-black AMOLED toggle, all persisted), a Playback section (infinite music), a Language selector, a Plugins section listing the active metadata and audio-source plugins with their versions, update/incompatibility status and per-plugin actions (check for update, update, reinstall, replace with another catalog plugin), and an Application section (the app version with its update status, plus an About page with the app icon, founder and repository links, and the license). Plugin archives are installed into an immutable, versioned store (`plugins/<type>/<id>/<version>`): each version is extracted into a fresh path and validated (manifest type/SDK) before activation, a switch only moves the active pointer, and plugin data (`auth.json`) stays per plugin and survives a version change. Replacing a plugin logs out only the old one and clears the playback queue and the saved-media index because track ids belong to the provider that produced them. When a plugin exposes authentication, the detail page shows its account (sign in/sign out) between the version and the technical actions (Version → Account → Actions), with a small repository link under the plugin description when the manifest declares one. Contextual sign-in prompts appear when content or an action requires authentication, as a single message plus a "Sign in" snackbar action; browsing and playback stay anonymous.
* **Library & Saved Content**: Saved playlists, albums and artists tabs kept in sync with the active provider, a pinned *Liked Songs* list, playlist creation from the library or from a track's sheet, and per-track removal by swipe. The saved state is global and optimistic, so search, details, player and track sheet show and toggle the same value, and *Add to playlist* offers the playlists you own.
* **Covers & Sharing**: Covers are cached on disk, playlists with at least two covers render a 2×2 mosaic, and any album, artist, playlist or track can be shared as text plus link through the system share sheet.
* **Dynamic UI Generation**: The Home screen is generated entirely based on the sections (e.g., "Top Charts", "New Releases") returned by the active Metadata plugin.
* **Modular Details Views**: Rich Slivers-based UI for Artists, Albums, and Playlists.
* **In-App Updates**: one silent update check per cold start, an `Update` dialog that leads straight to the verified download (SHA-256, APK signature and versionCode checked before the system installer opens), progress and cancellation in Settings → Application → App version, and the Android installer prompt as the only installation step.

---

## 🛠️ Tech Stack

* **Framework**: Flutter 3.44+ (Material 3 Design System)
* **State Management**: `flutter_bloc` (Cubits)
* **Routing & DI**: `go_router` (Stateful Shell Routes) & `get_it`
* **Audio Engine**: `just_audio` & `audio_service`
* **Plugin Subsystem**:
  * `musicare_plugin_sdk` (Pure-Python plugin SDKs, shared host runtime and Dart host SDKs)
  * `serious_python` 6 (embedded CPython 3.14 host daemon)
* **Covers & Persistence**: `cached_network_image` (on-disk cover cache) & `shared_preferences` (settings, plugin account ids)

---

## 🏗️ System Architecture

MusicAre follows a decoupled, Feature-First Clean Architecture organized into well-defined layers:

```text
┌──────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  (UI pages, widgets, slivers, mini- & full-player)       │
└──────────────────────────────────────────────────────────┘
                            │ state & commands
                            ▼
┌──────────────────────────────────────────────────────────┐
│                  STATE MANAGEMENT LAYER                  │
│  Global (GetIt): PluginSessionCubit, PluginManagerCubit, │
│    UserCubit, PlayerCubit, ThemeCubit                    │
│  Local: page-scoped cubits (Home, Search, Details, …)    │
└──────────────────────────────────────────────────────────┘
                            │ page → cubit → repository → engine
                            ▼
┌──────────────────────────────────────────────────────────┐
│                        DATA LAYER                        │
│  Repositories: Media, Browse, Search, Playlist, Library  │
│  Engines: MetadataPluginEngine, AudioSourcePluginEngine  │
│  Services: AudioPlayerService (+ AudioStreamResolver,    │
│    MusicAreAudioHandler), PluginCatalog, PluginManager,  │
│    PluginRegistry, PluginStorage, MetadataAuthPresenter  │
└──────────────────────────────────────────────────────────┘
                            │ HTTP + JSON on loopback
                            ▼
┌──────────────────────────────────────────────────────────┐
│           PYTHON RUNTIME (one CPython process)           │
│  Metadata daemon: Flask, ephemeral port, plugin .zip     │
│  Audio daemon: Flask, ephemeral port, plugin .zip        │
│  two-tier JIT: search_candidates → resolve_stream        │
│  shared by both: plugin_runtime and the host SDKs        │
└──────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

1. **Presentation Layer (UI & Navigation)**: UI pages, reusable widgets and the `GoRouter` configuration (a stateful shell plus a dedicated navigator for the player).
2. **State Management Layer (Cubits)**:
   * **Global cubits** (GetIt singletons, provided from `main.dart`): `PluginSessionCubit` (active plugins: lifecycle + account), `PluginManagerCubit` (install/update/replace), `UserCubit` (session, saved-media index, library mutations), `PlayerCubit` (queue, playback, radio), `AppUpdateCubit` (update check, download, install hand-off) and `ThemeCubit`.
   * **Local cubits**: page-scoped state machines created and disposed with their page (`HomeCubit`, `SearchCubit`, `LibraryCubit`, …).
3. **Data Layer**:
   * **Repositories** (`lib/features/plugin/metadata/data/repositories/`): one thin, stateless repository per domain (media, browse, search, playlist, library) that narrows the plugin engine to the calls its domain needs. The direction is always page → cubit → repository → engine: **no cubit imports a plugin engine**.
   * **Engines and player services**: `MetadataPluginEngine` and `AudioSourcePluginEngine` own the wire protocol; `AudioPlayerService` (with `AudioStreamResolver` and `MusicAreAudioHandler`) owns queue advancement, stream resolution and fallback, and the media session, and is the only path from the player to the audio engine. `ListeningTracker` reads the player stream once and feeds the listen sinks (the metadata account history today).
   * **Plugin management**: `PluginCatalog` (GitHub releases with a TTL cache), `PluginManager` (install/activation and the active pointer), `PluginRegistry` (capabilities per plugin type), `PluginStorage` (versioned plugin store: layout and pruning), `PluginRuntimeBoot` (starts or attaches to the plugin runtime and prepares the store before the boot) and `MetadataAuthPresenter` (host-side login form).
4. **Services & infrastructure** (`lib/core/`): `PreferencesService`, `NetworkService`, `NoticeBus` (global UI notices) and `AppInitializer`, registered in GetIt.
   * **Error presentation**: `NoticeBus` + `NoticeListener` (the single snackbar renderer) live in `core/notice/`. Every domain ships an `ErrorTable` (`MetadataErrorTable`, `AudioErrorTable`, `RuntimeErrorTable`, `PluginErrorTable`, `UpdateErrorTable`) that maps its own `sealed` exceptions to localized texts and, where needed, an action; `appErrorPresentation` (`core/errors/app_error_presentation.dart`) composes the tables once for both DI and the startup screen, unwraps rethrown errors and falls back to the generic message.
5. **Plugin Subsystems**: a single `serious_python` process hosts the metadata and audio-source Flask apps on two ephemeral ports; each daemon loads its plugin `.zip` at runtime and speaks JSON over loopback.

The two data paths meet only in the UI. **Content** (home, search, details, library) flows page → cubit → repository → `MetadataPluginEngine`. **Playback** flows `PlayerCubit` → `AudioPlayerService` → `AudioStreamResolver` → `AudioSourcePluginEngine` (two-tier JIT: `searchCandidates`, then `resolveStream` on demand), with audio output through `AudioPlayerDriver` (`just_audio`) and the notification/lock-screen session through `MusicAreAudioHandler` (`audio_service`).

### Startup and runtime lifecycle

`main` awaits `AppInitializer.initialize()` inside a `try/catch` and never leaves the splash on a failure: either the app is mounted with the location the bootstrap computed, or the failure is logged with its stack (`FlutterError.reportError`) and the process exits. There is deliberately no error screen and no Retry: `initDependencies` *is* the runtime boot, so without a working runtime there is no container and no app in which to show anything, and the embedded interpreter cannot be booted twice in one process — a second attempt would fail the same way. The next launch starts from a clean process, which is the only real recovery. The exit lives in `main` because that is where process lifetime belongs: the initializer only returns a location.

The container is built in two phases so the boundary stays visible: `initCoreDependencies()` registers what does not depend on the daemon ports (preferences, theme, notices, error tables, the `PluginStorage`, and the `PluginRuntimeBoot` that owns the `RuntimeHost` and produces the ports), `AppInitializer` boots the runtime, and `initRuntimeDependencies(ports)` registers everything built from the ports (engines, repositories, cubits, player, tracker). The rule is about dependency, not folders: `PluginRuntimeBoot` lives with the plugin services but is registered in the core phase because it receives no ports, it produces them.

`PluginRuntimeBoot` (`lib/features/plugin/shared/data/services/plugin_runtime_boot.dart`) resolves the two daemon ports. `serious_python` initialises the interpreter once per process and cannot restart it (its `terminate()` is a no-op on Android), so a new Dart isolate — the activity was destroyed, the process was not — cannot boot the daemons again. The ports are persisted with the id of the process that owns them (`runtime_session` in `PreferencesService`); when the same process is still serving both, the new isolate **attaches** to the running runtime instead of booting, and plugins are loaded again as on a normal start. A session written by another process (cold start, app update, reboot) is ignored, so the runtime is only reused when it is provably the same one.

The plugin store has a lifetime rule that follows from the wire protocol: a code dir passed to `/load_plugin` is **live code** and is never deleted while the interpreter runs, because a module another daemon already holds may read from it (the audio daemon's `yt_dlp` reads the metadata plugin's `certifi` CA bundle on every request). `PluginRuntimeBoot.start()` therefore prepares the store **before** the interpreter starts — never when attaching to a live one — and does the only thing that may touch paths: it keeps the active version of each plugin (`activePluginId` + `activePluginVersionDir`) and prunes everything else, removing an id with no active version entirely, data included. `PluginManager.apply` installs into a new `<versionDir>` path (a reinstall, or a switch back to a plugin whose old dir is still on disk, gets a numeric suffix) and only switches the pointer; a failed activation leaves the new path for the next boot to prune and keeps the active plugin and its data intact.

### Plugin capabilities and composition

The host treats plugin capabilities as independent, type-keyed services:

* `PluginLifecycle` is mandatory for every plugin: load/unload, compatibility and lifecycle state.
* `PluginAuth` is optional: authentication state, sign-in/out and account identity for plugins that expose it.
* A `PluginEntry` pairs the lifecycle with an optional auth adapter for one `PluginType`; its type comes from the lifecycle, so there is a single source of truth.
* `PluginRegistry` indexes the entries and is the composition point used by `PluginManager` and `PluginSessionCubit`.
* `MetadataPluginLifecycle` owns only the metadata engine; `MetadataPluginAuth` owns the auth flow and the account-id persistence through `PreferencesService`. `AudioSourcePluginLifecycle` has no auth entry. `PluginManager` logs out the old auth before switching plugins and refreshes the new one after activation.
* `UserCubit` owns the saved-library index and observes `PluginAuth`; it does not authenticate. Account UI reads `PluginSessionCubit` through `PluginAccountSection`.

Plugin updates are offered twice: a startup prompt (`PluginUpdatePrompt`, 1.5 s after the shell appears, once per process and **after** the app-update check — an available app update suppresses it for that launch) lists every slot with `updateAvailable` and applies them in sequence, one failure not stopping the others; and a manual *Check for update* in the plugin's Actions section, which forces the catalog refresh (`forceRefresh` through `PluginManagerCubit.refresh` → `PluginManager.snapshot` → `PluginCatalog.latest`) so a stale in-memory TTL can never be reported as fresh. Incompatible plugins are excluded from both: the setup page owns them.

### Listening history

`ListeningTracker` (`lib/features/listening/`) is the single reader of `AudioPlayerService.playbackDataStream`. It keeps one playback instance at a time (a new track, a cleared queue, or the same track restarting — repeat-one, replay, stop and play) and counts the **time actually played**: only position deltas up to two seconds while playing are summed, so seeks and pauses never inflate a listen. A track counts as a `single` at half its duration or four minutes, whichever comes first (tracks shorter than 30 s never count), with `listened_at` set to the instance start in UTC; `playing_now` is sent when the instance starts playing and again after a pause longer than five seconds. Events are deduped per `(kind, track, start instant)`.

The tracker hands events to a list of `ListenSink`s; today the only one is `MetadataHistorySink`, which writes to the active plugin's listen history when an account is signed in. Delivery is best-effort: every failure is logged, nothing is shown to the user, and an `unsupported` answer (the provider keeps no history) switches that destination off for the plugin — a different plugin id retries once, so replacing a provider needs no restart. Sharing follows the account: there is no separate switch, and a destination decides for itself whether it may receive an event. A metadata plugin switch also clears the playback queue and the saved index (`PluginSwitchReset`): track ids belong to the plugin that produced them.

---

## 📁 Project Directory Structure

```text
lib/
├── core/                           # Shared infrastructure, routing, DI, and services
│   ├── cubit/                      # SafeCubit and reactive state utilities
│   ├── di/                         # Service locator configuration (GetIt)
│   ├── l10n/                       # Localization and translations (.arb)
│   ├── models/                     # Universal UI models (MediaItemMetadata, MediaType)
│   ├── notice/                     # Global notices (NoticeBus, NoticeListener, error presentation)
│   ├── router/                     # Navigation rules and router configuration
│   ├── services/                   # Preferences, network client and app initialization
│   ├── theme/                      # Material 3 theme, accents and typography
│   ├── utils/                      # Fetch-all helpers, playlist ownership, media labels
│   └── widgets/                    # Reusable UI components (Slivers, matrices, carousels)
│
└── features/                       # Modular vertical feature slices
    ├── plugin/                     # Plugin subsystem (Catalog, Discovery, Management, Metadata, Audio Source)
    ├── onboarding/                 # Multi-step onboarding wizard
    ├── home/                       # Home page with dynamic browse sections
    ├── details/                    # Detail views (Album, Artist, Playlist)
    ├── search/                     # Polymorphic search (Tracks, Albums, Artists, Playlists) with context skeletons
    ├── library/                    # User library synced with active metadata provider
    ├── listening/                  # Listen tracking (single player reader) and listen sinks
    ├── player/                     # Native audio playback engine, Queue, MiniPlayer
    ├── settings/                   # Settings hub, appearance, playback, language, plugin details
    └── shell/                      # Root scaffold with bottom navigation
```

---

## 🚀 Quickstart & Setup

### 1. Prerequisites
* **Flutter SDK**: `v3.44.0` or higher (Dart 3.12.2+)
* **Python**: not required locally — `serious_python` bundles CPython 3.14 and pip for packaging (a local `python3` is only needed by the plugin platform repo's own test suite)
* **Android Target**: Android SDK / NDK configured (for mobile deployments)

### 2. SeriousPython Staging Setup
MusicAre embeds a single Python host runtime (two Flask daemons — metadata and audio source — on separate ephemeral ports) from the `musicare_plugin_sdk` platform repository. Before running the app for the first time, you **must** stage the Python runtime.

Fetch the Dart dependencies:
```bash
flutter pub get
```

Then run the staging script for your target platform:

**For Android:**
```bash
./tool/stage_python.sh Android
```

**For Linux Desktop:**
```bash
./tool/stage_python.sh Linux
```
*This script bundles Flask, the host runtime (including the shared `plugin_runtime` package), the plugin SDKs and the PIP dependencies into `build/python-app` and `build/site-packages`, exporting both variables for you. It then verifies the produced artifacts and exits with a non-zero code if any of them is missing or empty. It does **not** build the app: use `tool/build.sh` for that.*

#### Environment Variables
Gradle consumes the staging through **two** environment variables when `flutter build apk` runs:

- `SERIOUS_PYTHON_APP` — staging dir of the unpacked app, source of `assets/app.zip`. It has **no default**: when unset, the packaging is **silently skipped**, the build still succeeds and the APK contains no Python runtime at all (`serious_python` prints `Error: …` but exits `0`, and its Gradle task returns early).
- `SERIOUS_PYTHON_SITE_PACKAGES` — PIP dependencies, source of `assets/sitepackages.zip`. **Required by the Android build**: since `serious_python` 6.0.0 the Gradle plugin fails with `SERIOUS_PYTHON_SITE_PACKAGES environment variable is not set.` when it is missing (4.x silently defaulted to `<cwd>/build/site-packages`).

**VS Code** sets both of them for debug/run sessions via `.vscode/launch.json`, so no action is needed there. From a **terminal** both must be exported in the same shell that runs the build, which is what this single command does:
```bash
./tool/build.sh release   # or: ./tool/build.sh debug
```
It stages the runtime for Android first, verifies that `assets/app.zip` and `assets/sitepackages.zip` ended up inside the APK, and prints the APK path and size.

Note that `flutter clean` deletes `build/` and therefore the whole staging: re-run the script before the next build.

#### Build and release scripts
The tooling is split by job:

| Script | Purpose |
| :--- | :--- |
| `tool/stage_python.sh [Android\|Linux]` | Stages the Python runtime only (default: Android). |
| `tool/build.sh debug\|release` | Stages for Android, then runs `flutter build apk` in the same shell and checks the embedded runtime assets. |
| `tool/release.sh [--skip-checks] [--bump patch\|minor\|major] [--publish] [--notes <text> \| --notes-file <path>] [--no-push-branch]` | Release pipeline: `main` + clean tree, analyze/tests, keystore gate, tag/versionCode checks, release build, APK badging and signature gates, SHA-256. Without `--publish` it stops before the tag (dry run). |

The release version is the single source of truth in `pubspec.yaml` (`version: x.y.z+n`); the annotated tag is derived as `v<version>` (e.g. `v1.0.0+2`) and the release asset as `MusicAre-<versionName>.apk` (the APK is copied under that name before upload, because `gh` names assets after the file). `--bump` increments the version (and `+n`) and commits it before building; without it, no file is modified.

The release body is `MusicAre <version> (build <n>).` unless `--notes <text>` or `--notes-file <path>` is given: the two flags are mutually exclusive and an empty (or whitespace-only) body is rejected before anything is built. With `--publish` the script pushes the tag, creates the GitHub release and then pushes the branch (`git push origin main`), so the release commit is not left off `origin/main`; `--no-push-branch` keeps the branch local. The dry run prints the exact commands it would run, and never tags, pushes or publishes.

#### Release signing
The Android package is `com.musicare.app` (`applicationId` and `namespace`).

Release builds are signed **only** with the release keystore. `android/app/build.gradle.kts` reads `android/key.properties` (gitignored, next to `settings.gradle.kts`) with `storeFile`, `storePassword`, `keyAlias` and `keyPassword`, and creates the `release` signing config from it. There is **no fallback to the debug key**: when the file is missing, the release build fails up front with an explicit message instead of producing an APK that Android would refuse as an app update.

`tool/release.sh` pins the SHA-256 fingerprint of the release certificate: `apksigner verify --print-certs` must report exactly that digest, so an APK signed with any other key (debug key included) is rejected even though its signature is technically valid.

#### Cutting a release
Prerequisites: `main` checked out and clean, the release keystore in place (`android/key.properties`), `gh` authenticated against the repository, and a free tag `v<version>` whose `+n` is higher than the latest published release's.

```bash
./tool/release.sh                        # dry run: every gate, nothing written to git or GitHub
./tool/release.sh --publish              # tag, GitHub release, then push of the branch
./tool/release.sh --bump minor --publish # bump semver and +n first (committed before building)
./tool/release.sh --publish --notes-file notes-1.0.4.md  # release body from a file
./tool/release.sh --publish --notes "…" --no-push-branch # keep the branch local
```

The dry run is the recommended check before publishing: it runs analyze/tests, the keystore and tag gates, the release build, the badging and signature gates and prints the APK SHA-256. `--skip-checks` skips `flutter analyze` and `flutter test`.

#### In-app updates
`AppUpdateChecker` reads `https://api.github.com/repos/stefare90/musicare/releases/latest` once per cold start, 1.5 s after the shell appears (so onboarding never sees it), with `Accept: application/vnd.github+json` and a `User-Agent` carrying the installed version. A transport or API error is silent, nothing is cached and a dismissed dialog reappears on the next launch (`404` simply means there is no published release yet). Only a `vX.Y.Z+n` tag whose `versionCode` is strictly greater than the installed one and whose `.apk` asset has a size, a `sha256:` digest and a download URL is offered.

Progress and cancellation live in **Settings → Application → App version**, which also shows the installed version and a manual *Check for update*; the same state is summarized in the hub row. The download goes into `<filesDir>/updates` (`updatesDir()` from the `com.musicare.app_update` method channel, so Dart and the `FileProvider` share the path), is written as `.part` with the SHA-256 computed while streaming, and is renamed only after it matches the release digest. A verified APK for the same release is reused without a network call; `Cancel` deletes the partial file. Before the installer is opened, `apkInfo()` reads the package name, `versionCode` and signing certificate from the APK and checks them against the installed app and the release; a mismatch deletes the file. The install itself is an `ACTION_VIEW` intent on a `content://` URI (authority `${applicationId}.fileprovider`) that opens the Android installer prompt. Package name, version and certificate are derived at runtime — there are no signing constants in the repository, so a fork signed with another key updates itself.

#### License
MusicAre is released under the **BSD-3-Clause** license (see [LICENSE](LICENSE)). The `LICENSE` file is bundled as a Flutter asset and registered in `LicenseRegistry`, so About → License opens the standard license page with the app license and the licenses of all dependencies.

### 3. Run the App
Once the Python backend is staged, you can run the app normally:
```bash
flutter run
```

After building an APK, verify that it actually embeds the runtime:
```bash
unzip -l build/app/outputs/flutter-apk/app-*.apk | grep -E 'app\.zip|sitepackages\.zip'
```
Both `assets/app.zip` and `assets/sitepackages.zip` must be listed with a non-zero size: this is the only straightforward check for an APK that was built without Python.

#### Installing an APK on a device
```bash
./tool/build.sh release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

`adb install -r` replaces the APK and keeps the app data (installed plugins, account, preferences). Do not use `flutter install` for this: it first tries `adb install -t -r`, but when that fails it **uninstalls** the app and installs it again, wiping the plugins and the signed-in account without asking. With plain `adb` a failed install is just an error message and the decision stays with you.

The reinstall is refused (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`, `INSTALL_FAILED_VERSION_DOWNGRADE`) when the new APK is signed with a different key — debug vs release — or its `versionCode` is lower; in those cases the data has to go (`adb uninstall com.musicare.app`). The package is `com.musicare.app`, so a device still running an old `com.example.music_are` build gets a separate, fresh installation. A release APK is not debuggable: `adb shell run-as com.musicare.app` only works on debug builds.

---

## 🗺️ Project Roadmap

For what is implemented and what is still missing, per feature area, see the [Feature Status Ledger](documents/ROADMAP.md).

---

## 📄 License

BSD-3-Clause — see [LICENSE](LICENSE).
