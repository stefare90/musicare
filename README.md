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
* **Universal Media Player**: Native background playback support (`audio_service`) with lock-screen controls, gapless transitions, and hardware media key bindings.
* **Smart Queue Management**: Advanced immutable queue system supporting shuffle (preserving history), repeat modes (One, All, Off), and dynamic inserts. Playing from a partially loaded list keeps loading the rest in the background, with loading and retry states in the queue sheet.
* **Infinite Radio**: *Start radio* from any track's options replaces the queue with the seed plus a provider-generated radio batch (ListenBrainz `lb-radio`, requires sign-in). When the provider has no similar tracks, the current queue is left untouched and the app says so. With the persisted *Infinite music* switch (Settings → Playback, on by default) the queue keeps extending from the last played track when it ends — chained batch after batch and de-duplicated against the queue; signed-out playback simply stops at the end.
* **Fault-Tolerant Streaming**: Automatic candidate resolution—if a stream URL expires or returns a 403 Forbidden, the player automatically falls back to the next available stream. When a track cannot be resolved at all (no candidates, no stream, or a `not_found` from the audio plugin) the failure is still reported and playback advances to the next queue track, bounded to one pass over the queue (also with repeat-all); transient errors (rate limit, transport) keep the current track.
* **Global Search & Filter Chips**: Integrated with the active Metadata plugin (`ISearch`), supporting debounced queries, aggregated search views, category pagination, and instant track playback.
* **Settings, Plugin Management & Accounts**: A settings hub (gear on the three root screens) with an Appearance section (system/light/dark theme, accent color and an absolute-black AMOLED toggle, all persisted), a Playback section (infinite music), a Language selector, a Plugins section listing the active metadata and audio-source plugins with their versions, update/incompatibility status and per-plugin actions (update, reinstall, replace with another catalog plugin), and an About page (app and host SDK versions). Plugin archives are installed atomically (`.new` extraction, manifest/type/SDK validation, `.bak` rollback if activation fails); replacing a plugin logs out only the old one, removes its code and never touches plugin data. When a plugin exposes authentication, the detail page shows its account (sign in/sign out) between the version and the technical actions (Version → Account → Actions). Contextual sign-in prompts appear when content or an action requires authentication, as a single message plus a "Sign in" snackbar action; browsing and playback stay anonymous.
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
  * `serious_python` (Embedded CPython 3.10+ host daemon)

---

## 🏗️ System Architecture

MusicAre follows a decoupled, Feature-First Clean Architecture organized into well-defined layers:

```text
┌────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                    │
│      (UI Pages, Slivers, Mini-Player & Full-Player)    │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                 STATE MANAGEMENT LAYER                 │
│                                                        │
│ ┌──────────────────────┐      ┌──────────────────────┐ │
│ │ LOCAL STATE MACHINES │      │GLOBAL STATE MACHINES │ │
│ │ (Screen-Level Cubit) │ ◄────│ (Plugins, User,      │ │
│ │ (e.g. Home, Details) │      │  Player & Queue)     │ │
│ └──────────┬───────────┘      │                      │ │
│            │                  └──────────┬───────────┘ │
└────────────┼─────────────────────────────┼─────────────┘
             │                             │
             ▼                             ▼
┌────────────────────────────────────────────────────────┐
│                  SERVICES LAYER (IoC)                  │
│                                                        │
│  * MetadataPluginEngine (Wire protocol + SemVer check) │
│  * AudioSourcePluginEngine (Candidate search)          │
│  * AudioPlayerService (Resolution, fallback & queue)   │
│  * PluginCatalog (GitHub releases, TTL cache)          │
│  * PluginManager (install/activate transactions)       │
│  * PluginRegistry (lifecycle + optional auth per type) │
│  * MetadataAuthPresenter (Plugin login form)           │
└──────────────────────────┬─────────────────────────────┘
                           │ (Contract Injection)
                           ▼
┌────────────────────────────────────────────────────────┐
│                   PLUGIN SUBSYSTEMS                    │
├────────────────────────────┬───────────────────────────┤
│     METADATA DAEMON        │   AUDIO SOURCE DAEMON     │
│  (CPython + Flask)         │ (CPython + Flask)         │
│                            │                           │
│  * Python plugin (.zip)    │  * Python plugin (.zip)   │
│  * JSON wire protocol      │  * Two-tier JIT resolve   │
│  * Ephemeral port          │  * Ephemeral port         │
└────────────────────────────┴───────────────────────────┘
```

### Layer Responsibilities

1. **Presentation Layer (UI & Navigation)**: Composed of UI pages, reusable widgets, and `GoRouter` declarative navigation configurations.
2. **State Management Layer (Cubits)**:
   * **Global Cubits**: App-level singletons managing cross-cutting state (`PluginSessionCubit`, `UserCubit`, `PluginManagerCubit`, `PlayerCubit`, `ThemeCubit`).
   * **Local Cubits**: Screen-scoped state machines instantiated for specific pages and destroyed when navigating away.
3. **Services Layer (IoC / Dependency Injection)**: Houses central application services registered in `GetIt`, including host storage, native network clients, `AudioPlayerDriver`, and Plugin Engines.
4. **Plugin Subsystems**: Interpreters acting as data providers decoupled from the Flutter UI thread.

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
│   ├── router/                     # Navigation rules and router configuration
│   └── widgets/                    # Reusable UI components (Slivers, matrices, carousels)
│
└── features/                       # Modular vertical feature slices
    ├── plugin/                     # Dynamic plugin subsystem (Catalog, Management, Metadata, Audio Source)
    ├── onboarding/                 # Multi-step onboarding wizard
    ├── home/                       # Home page with dynamic browse sections
    ├── details/                    # Detail views (Album, Artist, Playlist)
    ├── search/                     # Polymorphic search (Tracks, Albums, Artists, Playlists) with context skeletons
    ├── library/                    # User library synced with active metadata provider
    ├── player/                     # Native audio playback engine, Queue, MiniPlayer
    └── shell/                      # Root scaffold with bottom navigation
```

---

## 🚀 Quickstart & Setup

### 1. Prerequisites
* **Flutter SDK**: `v3.44.0` or higher (Dart 3.12+)
* **Python**: `3.10+` (used by SeriousPython's standalone packaging tool)
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
./tool/build_python.sh Android
```

**For Linux Desktop:**
```bash
./tool/build_python.sh Linux
```
*This script bundles Flask, the host runtime (including the shared `plugin_runtime` package), the plugin SDKs and the PIP dependencies into `build/python-app` and `build/site-packages`, exporting both variables for you. It then verifies the produced artifacts and exits with a non-zero code if any of them is missing or empty.*

#### Environment Variables
Gradle consumes the staging through **two** environment variables when `flutter build apk` runs:

- `SERIOUS_PYTHON_APP` — staging dir of the unpacked app, source of `assets/app.zip`. It has **no default**: when unset, the packaging is **silently skipped**, the build still succeeds and the APK contains no Python runtime at all (`serious_python` prints `Error: …` but exits `0`, and its Gradle task returns early).
- `SERIOUS_PYTHON_SITE_PACKAGES` — PIP dependencies, source of `assets/sitepackages.zip`. **Required by the Android build**: since `serious_python` 6.0.0 the Gradle plugin fails with `SERIOUS_PYTHON_SITE_PACKAGES environment variable is not set.` when it is missing (4.x silently defaulted to `<cwd>/build/site-packages`).

**VS Code** sets both of them for debug/run sessions via `.vscode/launch.json`, so no action is needed there. From a **terminal** both must be exported in the same shell that runs the build, which is what this single command does:
```bash
./tool/build_python.sh Android apk
```

Note that `flutter clean` deletes `build/` and therefore the whole staging: re-run the script before the next build.

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

---

## 🗺️ Project Roadmap

For what is implemented and what is still missing, per feature area, see the [Feature Status Ledger](documents/ROADMAP.md).