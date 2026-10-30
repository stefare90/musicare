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
* **Fault-Tolerant Streaming**: Automatic candidate resolution—if a stream URL expires or returns a 403 Forbidden, the player automatically falls back to the next available stream. When a track cannot be resolved at all (no candidates, no stream, or a `not_found` from the audio plugin) the failure is still reported and playback advances to the next queue track, bounded to one pass over the queue (also with repeat-all); transient errors (rate limit, transport) keep the current track.
* **Global Search & Filter Chips**: Integrated with the active Metadata plugin (`ISearch`), supporting debounced queries, aggregated search views, category pagination, and instant track playback.
* **Settings, Plugin Management & Accounts**: A settings hub (gear on the three root screens) with an Appearance section (system/light/dark theme, accent color and an absolute-black AMOLED toggle, all persisted), a Playback section (infinite music), a Language selector, a Plugins section listing the active metadata and audio-source plugins with their versions, update/incompatibility status and per-plugin actions (update, reinstall, replace with another catalog plugin), and an About page (app and host SDK versions). Plugin archives are installed atomically (`.new` extraction, manifest/type/SDK validation, `.bak` rollback if activation fails); replacing a plugin logs out only the old one, removes its code and never touches plugin data. When a plugin exposes authentication, the detail page shows its account (sign in/sign out) between the version and the technical actions (Version → Account → Actions). Contextual sign-in prompts appear when content or an action requires authentication, as a single message plus a "Sign in" snackbar action; browsing and playback stay anonymous.
* **Library & Saved Content**: Saved playlists, albums and artists tabs kept in sync with the active provider, a pinned *Liked Songs* list, playlist creation from the library or from a track's sheet, and per-track removal by swipe. The saved state is global and optimistic, so search, details, player and track sheet show and toggle the same value, and *Add to playlist* offers the playlists you own.
* **Covers & Sharing**: Covers are cached on disk, playlists with at least two covers render a 2×2 mosaic, and any album, artist, playlist or track can be shared as text plus link through the system share sheet.
* **Dynamic UI Generation**: The Home screen is generated entirely based on the sections (e.g., "Top Charts", "New Releases") returned by the active Metadata plugin.
* **Modular Details Views**: Rich Slivers-based UI for Artists, Albums, and Playlists.

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
   * **Global cubits** (GetIt singletons, provided from `main.dart`): `PluginSessionCubit` (active plugins: lifecycle + account), `PluginManagerCubit` (install/update/replace), `UserCubit` (session, saved-media index, library mutations), `PlayerCubit` (queue, playback, radio) and `ThemeCubit`.
   * **Local cubits**: page-scoped state machines created and disposed with their page (`HomeCubit`, `SearchCubit`, `LibraryCubit`, …).
3. **Data Layer**:
   * **Repositories** (`lib/features/plugin/metadata/data/repositories/`): one thin, stateless repository per domain (media, browse, search, playlist, library) that narrows the plugin engine to the calls its domain needs. The direction is always page → cubit → repository → engine: **no cubit imports a plugin engine**.
   * **Engines and player services**: `MetadataPluginEngine` and `AudioSourcePluginEngine` own the wire protocol; `AudioPlayerService` (with `AudioStreamResolver` and `MusicAreAudioHandler`) owns queue advancement, stream resolution and fallback, and the media session, and is the only path from the player to the audio engine.
   * **Plugin management**: `PluginCatalog` (GitHub releases with a TTL cache), `PluginManager` (install/activate transactions), `PluginRegistry` (capabilities per plugin type), `PluginStorage` (plugin code and manifests on disk) and `MetadataAuthPresenter` (host-side login form).
4. **Services & infrastructure** (`lib/core/`): `PreferencesService`, `NetworkService`, `NoticeBus` (global UI notices) and `AppInitializer`, registered in GetIt.
5. **Plugin Subsystems**: a single `serious_python` process hosts the metadata and audio-source Flask apps on two ephemeral ports; each daemon loads its plugin `.zip` at runtime and speaks JSON over loopback.

The two data paths meet only in the UI. **Content** (home, search, details, library) flows page → cubit → repository → `MetadataPluginEngine`. **Playback** flows `PlayerCubit` → `AudioPlayerService` → `AudioStreamResolver` → `AudioSourcePluginEngine` (two-tier JIT: `searchCandidates`, then `resolveStream` on demand), with audio output through `AudioPlayerDriver` (`just_audio`) and the notification/lock-screen session through `MusicAreAudioHandler` (`audio_service`).

### Plugin capabilities and composition

The host treats plugin capabilities as independent, type-keyed services:

* `PluginLifecycle` is mandatory for every plugin: load/unload, compatibility and lifecycle state.
* `PluginAuth` is optional: authentication state, sign-in/out and account identity for plugins that expose it.
* A `PluginEntry` pairs the lifecycle with an optional auth adapter for one `PluginType`; its type comes from the lifecycle, so there is a single source of truth.
* `PluginRegistry` indexes the entries and is the composition point used by `PluginManager` and `PluginSessionCubit`.
* `MetadataPluginLifecycle` owns only the metadata engine; `MetadataPluginAuth` owns the auth flow and the account-id persistence through `PreferencesService`. `AudioSourcePluginLifecycle` has no auth entry. `PluginManager` logs out the old auth before switching plugins and refreshes the new one after activation.
* `UserCubit` owns the saved-library index and observes `PluginAuth`; it does not authenticate. Account UI reads `PluginSessionCubit` through `PluginAccountSection`.

---

## 📁 Project Directory Structure

```text
lib/
├── core/                           # Shared infrastructure, routing, DI, and services
│   ├── cubit/                      # SafeCubit and reactive state utilities
│   ├── di/                         # Service locator configuration (GetIt)
│   ├── l10n/                       # Localization and translations (.arb)
│   ├── models/                     # Universal UI models (MediaItemMetadata, MediaType)
│   ├── notice/                     # Global notices (NoticeBus and snackbar policy)
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
| `tool/release.sh [--skip-checks] [--bump patch\|minor\|major] [--publish]` | Release pipeline: `main` + clean tree, analyze/tests, keystore gate, tag/versionCode checks, release build, APK badging and signature gates, SHA-256. Without `--publish` it stops before the tag (dry run). |

The release version is the single source of truth in `pubspec.yaml` (`version: x.y.z+n`); the annotated tag is derived as `v<version>` (e.g. `v1.0.0+2`) and the release asset as `MusicAre-<versionName>.apk` (the APK is copied under that name before upload, because `gh` names assets after the file). `--bump` increments the version (and `+n`) and commits it before building; without it, no file is modified.

#### Release signing
The Android package is `com.musicare.app` (`applicationId` and `namespace`).

Release builds are signed **only** with the release keystore. `android/app/build.gradle.kts` reads `android/key.properties` (gitignored, next to `settings.gradle.kts`) with `storeFile`, `storePassword`, `keyAlias` and `keyPassword`, and creates the `release` signing config from it. There is **no fallback to the debug key**: when the file is missing, the release build fails up front with an explicit message instead of producing an APK that Android would refuse as an app update.

`tool/release.sh` pins the SHA-256 fingerprint of the release certificate: `apksigner verify --print-certs` must report exactly that digest, so an APK signed with any other key (debug key included) is rejected even though its signature is technically valid.

#### Cutting a release
Prerequisites: `main` checked out and clean, the release keystore in place (`android/key.properties`), `gh` authenticated against the repository, and a free tag `v<version>` whose `+n` is higher than the latest published release's.

```bash
./tool/release.sh                        # dry run: every gate, nothing written to git or GitHub
./tool/release.sh --publish              # git tag, push and GitHub release
./tool/release.sh --bump minor --publish # bump semver and +n first (committed before building)
```

The dry run is the recommended check before publishing: it runs analyze/tests, the keystore and tag gates, the release build, the badging and signature gates and prints the APK SHA-256. `--skip-checks` skips `flutter analyze` and `flutter test`.

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