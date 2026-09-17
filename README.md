# 🎵 MusicAre
<p align="center">
  <img src="assets/images/readme_header.png" alt="MusicAre Header" width="100%">
</p>

> Music are the plugins. We are the player.

`MusicAre` is an extensible, flexible, and lightweight music playback application. The core concept is straightforward: **the host application handles the visual user interface, navigation, track queue, and native audio playback, while all music metadata (tracks, albums, artists, search, playlists) and audio streams are provided by dynamic, hot-swappable external plugins.**

The application supports two distinct plugin subsystems:
* **Metadata Plugins**: Compiled into `.evc` bytecode, packaged as `.zip` archives, and interpreted dynamically at runtime using `dart_eval`.
* **Audio Source Plugins**: Written in 100% Pure-Python, packaged as `.zip` archives, and dynamically injected at runtime into a persistent embedded CPython daemon via `serious_python` and `musicare_dart_host_sdk`.

---

## ✨ Current Features

* **Dynamic Onboarding Wizard**: Effortlessly discover, download, and configure your preferred Metadata and Audio Source plugins straight from GitHub releases.
* **Universal Media Player**: Native background playback support (`just_audio_background`) with lock-screen controls, gapless transitions, and hardware media key bindings.
* **Smart Queue Management**: Advanced immutable queue system supporting shuffle (preserving history), repeat modes (One, All, Off), and dynamic inserts.
* **Fault-Tolerant Streaming**: Automatic candidate resolution—if a stream URL expires or returns a 403 Forbidden, the player automatically falls back to the next available stream.
* **Global Search & Filter Chips**: Integrated with the active Metadata plugin (`ISearch`), supporting debounced queries, dynamic filter chips, aggregated search views, category pagination, and instant track playback.
* **Dynamic UI Generation**: The Home screen is generated entirely based on the sections (e.g., "Top Charts", "New Releases") returned by the active Metadata plugin.
* **Modular Details Views**: Rich Slivers-based UI for Artists, Albums, and Playlists.

---

## 🛠️ Tech Stack

* **Framework**: Flutter 3.12+ (Material 3 Design System)
* **State Management**: `flutter_bloc` (Cubits)
* **Routing & DI**: `go_router` (Stateful Shell Routes) & `get_it`
* **Audio Engine**: `just_audio` & `just_audio_background`
* **Plugin Subsystems**:
  * `dart_eval` (Sandboxed Dart Bytecode execution)
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
│ │ (Screen-Level Cubit) │ ◄────│ (Metadata, Audio,    │ │
│ │ (e.g. Home, Details) │      │  Player & Queue)     │ │
│ └──────────┬───────────┘      │                      │ │
│            │                  └──────────┬───────────┘ │
└────────────┼─────────────────────────────┼─────────────┘
             │                             │
             ▼                             ▼
┌────────────────────────────────────────────────────────┐
│                  SERVICES LAYER (IoC)                  │
│                                                        │
│  * MetadataPluginEngine (Bytecode VM & SemVer check)   │
│  * AudioSourcePluginEngine (High-Level Orchestrator)   │
│  * AudioPlayerService (Playback & Fallback driver)     │
│  * PluginDiscoveryService (GitHub Release Downloader)  │
│  * SDK Adapters (PluginNetwork, PluginStorage, UI)     │
└──────────────────────────┬─────────────────────────────┘
                           │ (Contract Injection)
                           ▼
┌────────────────────────────────────────────────────────┐
│                   PLUGIN SUBSYSTEMS                    │
├────────────────────────────┬───────────────────────────┤
│     METADATA SANDBOX       │   AUDIO SOURCE DAEMON     │
│  (dart_eval Runtime / VM)  │ (SeriousPython + Flask)   │
│                            │                           │
│  * In-memory Bytecode .evc │  * Fixed Host Runtime     │
│  * Host SDK Bridge         │  * Dynamic /load_plugin   │
│  * Pure Native Dart Types  │  * Ephemeral Port REST    │
└────────────────────────────┴───────────────────────────┘
```

### Layer Responsibilities

1. **Presentation Layer (UI & Navigation)**: Composed of UI pages, reusable widgets, and `GoRouter` declarative navigation configurations.
2. **State Management Layer (Cubits)**:
   * **Global Cubits**: App-level singletons managing cross-cutting state (`MetadataPluginCubit`, `AudioSourcePluginCubit`, `PlayerCubit`).
   * **Local Cubits**: Screen-scoped state machines instantiated for specific pages and destroyed when navigating away.
3. **Services Layer (IoC / Dependency Injection)**: Houses central application services registered in `GetIt`, including host storage, native network clients, `AudioPlayerDriver`, and Plugin Engines.
4. **Plugin Subsystems**: Interpreters acting as data providers decoupled from the Flutter UI thread.

### Responsive Media Cards & Skeletons

The geometry of `MediaCard` and of every skeleton that mimics it is centralized in **`MediaCardMetrics`** (`lib/core/widgets/media/media_card_metrics.dart`), the single source of truth for:

* Horizontal rhythm: `edgeInset` (16) and the gap between cards (12), shared by grids, horizontal `SectionRow`s and section titles.
* Card sizing: `minCardWidth` / `maxCardWidth` for grid column computation and the fixed `rowCardWidth` (150) of horizontal rows. The card no longer imposes a fixed width nor carries its own margin: the calling layout owns the spacing.
* **`TextScaler`-aware text block height**: computed via `TextPainter` + `MediaQuery.textScalerOf`, so the card text area grows with the user font size.

The `_PaginatedMediaGrid` (search Albums/Artists/Playlists) builds its `SliverGridDelegateWithFixedCrossAxisCount` with `mainAxisExtent = cellWidth + textBlockHeight`, guaranteeing a square cover and a text block that always fits, regardless of `textScaler` (verified at 1.0/1.3/1.5/2.0). `SkeletonMediaGrid`, `SkeletonSectionRow` and `SkeletonSearchAll` reuse the exact same metrics, so placeholders are pixel-coherent with the loaded results (no visual jump).

#### Column-aligned pagination & scrollable non-list states

`SearchCubit` always requests a `limit` that is a whole number of grid rows. The view computes the actual column count from the available width (`MediaCardMetrics.gridColumns`) and notifies the cubit through `updateGridColumns(int)`, a pure setter that never emits state (stale-value guarded) so it can be called from a post-frame callback without triggering a rebuild loop. `MediaCardMetrics.pageSizeForColumns(pageSize, columns)` rounds the page size up to the nearest multiple of the columns, so the grid categories (Albums/Artists/Playlists) never end with a partially filled row; the track list keeps the raw `pageSize`. `SkeletonMediaGrid` applies the same rounding to its placeholder count, and the progressive loading of a grid category (`loadMore`) appends a **full row of skeleton cells** (`columns` × `ShimmerBox`) instead of a lone `CircularProgressIndicator`, keeping the grid rhythm coherent with the initial skeleton.

The non-list states (empty query, error, no results) are rendered through a `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight)` wrapper: they stay vertically centered when there is room and become scrollable on short viewports (landscape, keyboard open), eliminating any `RenderFlex` overflow.

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
    ├── plugin/                     # Dynamic plugin subsystem (Discovery, Metadata, Audio Source)
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
* **Flutter SDK**: `v3.12.0` or higher
* **Python**: `3.10+` (used by SeriousPython's standalone packaging tool)
* **Android Target**: Android SDK / NDK configured (for mobile deployments)

### 2. SeriousPython Staging Setup
MusicAre embeds a fixed Python host runtime daemon from the `musicare_audiosource_sdk` monorepo. Before running the app for the first time, you **must** stage the Python runtime.

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
*This script automatically bundles Flask, the host runtime, and installs PIP dependencies into `build/site-packages`.*

### 3. Run the App
Once the Python backend is staged, you can run the app normally:
```bash
flutter run
```

---

## 🗺️ Project Roadmap

To track progressive implementation milestones and upcoming tasks, please refer to the [Implementation Roadmap](documents/ROADMAP.md).