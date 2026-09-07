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

## 🎯 Architectural Vision

The application serves as a universal, service-agnostic playback framework:
* **Separation of Responsibilities**: The host application focuses on native performance, UI, and audio playback, delegating content delivery to modular plugins.
* **Dual-Plugin Architecture**:
  * **Metadata Providers**: Query music catalogs and database entities (e.g. MusicBrainz, Spotify, Deezer).
  * **Audio Source Providers**: Resolve playable audio streams in real-time via scraping or streaming APIs (e.g. YouTube Music, SoundCloud, Invidious), returning fault-tolerant candidate streams.
* **Decentralized Discovery**: The application discovers community plugins on GitHub (`topic:musicare-plugin`), fetches release archives, and installs them locally.
* **Extensible & Updatable**: Plugins reside in local storage and are injected into memory on the fly without requiring host application restarts or recompilations.

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
│ │ (Screen-Level Cubit) │ ◄────│ (MetadataPluginCubit,│ │
│ │ (e.g. Home, Search)  │      │  AudioSourceCubit,   │ │
│ └──────────┬───────────┘      │  PlayerCubit)        │ │
│            │                  └──────────┬───────────┘ │
└────────────┼─────────────────────────────┼─────────────┘
             │                             │
             ▼                             ▼
┌────────────────────────────────────────────────────────┐
│                  SERVICES LAYER (IoC)                  │
│                                                        │
│  * MetadataPluginEngine (Bytecode VM & SemVer check)   │
│  * AudioSourcePluginEngine (High-Level Orchestrator)   │
│  * AudioSourceClient (package:musicare_dart_host_sdk)  │
│  * PluginDiscoveryService (GitHub Release Downloader)  │
│  * PreferencesService (Native host settings)           │
│  * NetworkService (Native host HTTP client)            │
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
│                            │  * Ordered Fallbacks      │
└────────────────────────────┴───────────────────────────┘
```

### Layer Responsibilities

1. **Presentation Layer (UI & Navigation)**: Composed of UI pages, reusable widgets, and `GoRouter` declarative navigation configurations (such as the persistent shell, onboarding wizard, and mini-player).
2. **State Management Layer (Cubits & Blocs)**:
   * **Global Cubits**: App-level singletons managing cross-cutting state (`MetadataPluginCubit`, `AudioSourcePluginCubit`, `PlayerCubit`).
   * **Local Cubits**: Screen-scoped state machines instantiated for specific pages and destroyed when navigating away.
3. **Services Layer (IoC / Dependency Injection)**: Houses central application services registered in `GetIt`, including host storage, native network clients, GitHub discovery, `MetadataPluginEngine`, and `AudioSourcePluginEngine`.
4. **Plugin Subsystems**:
   * **Metadata**: Interprets `.evc` bytecode in an isolated VM via `dart_eval`.
   * **Audio Source**: Boots a fixed, pre-compiled CPython host daemon on an ephemeral localhost port via `serious_python`. External pure-Python plugins (`plugin.zip`) are extracted to app storage and dynamically injected via `POST /load_plugin`, resolving stream queries over `POST /get_stream`.

---

## 📁 Project Directory Structure

```text
lib/
├── core/                           # Shared core infrastructure, routing, DI, and host services
│   ├── cubit/                      # SafeCubit and reactive state utilities
│   ├── di/                         # Service locator configuration (GetIt)
│   ├── l10n/                       # Localization and translations (.arb)
│   ├── models/                     # Universal UI models (MediaItemMetadata, MediaType, SectionState)
│   ├── router/                     # Navigation rules and router configuration (GoRouter)
│   ├── services/                   # Native I/O host services (NetworkService, PreferencesService)
│   ├── theme/                      # Styling and design system
│   └── widgets/                    # Reusable UI components (Slivers, matrices, carousels, modal sheets)
│
└── features/                       # Modular vertical feature slices (Feature-First)
    ├── plugin/                     # Dynamic plugin subsystem
    │   ├── shared/                 # Common manifest (PluginManifest), types (PluginType), exceptions
    │   ├── discovery/              # GitHub topic:musicare-plugin discovery engine & UI
    │   ├── metadata/               # Dart bytecode VM engine & SDK host services (dart_eval)
    │   └── audio_source/           # Audio source orchestrator & cubit (consumes musicare_dart_host_sdk)
    │
    ├── onboarding/                 # Multi-step onboarding wizard
    │   └── presentation/
    │       ├── pages/              # welcome_page, welcome_intro_page, welcome_metadata_page, welcome_audio_source_page
    │       └── widgets/            # onboarding_step_scaffold, onboarding_bottom_action_button, onboarding_dots_indicator
    │
    ├── home/                       # Home page with dynamic browse sections
    ├── details/                    # Detail views (Album, Artist, Playlist)
    ├── search/                     # Polymorphic search (Tracks, Albums, Artists, Playlists)
    ├── library/                    # User library synced with active metadata provider
    ├── player/                     # Native audio playback engine, MiniPlayer & FullPlayer
    └── shell/                      # Root scaffold with bottom navigation & persistent MiniPlayer
```

---

## ⚙️ Development Environment Setup

### 1. Prerequisites
* **Flutter SDK**: `v3.12.0` or higher
* **Python**: `3.10+` (used by SeriousPython's standalone packaging tool)
* **Android SDK / NDK**: Standard Android toolchain for mobile deployments

---

### 2. SeriousPython Staging Setup
MusicAre embeds a fixed Python host runtime daemon from the `musicare_audiosource_sdk` monorepo. 

Before building the Flutter app for the first time (or after updating the SDK), run the staging script to bundle Flask and the host runtime:

#### Target Android
```bash
./tool/build_python.sh Android
```

#### Target Linux Desktop
```bash
./tool/build_python.sh Linux
```

This script automatically prepares the runtime in `build/python-app` and installs dependencies into `build/site-packages`.

---

## 🗺️ Project Roadmap

To track progressive implementation milestones and upcoming tasks, please refer to the [Implementation Roadmap](documents/ROADMAP.md).