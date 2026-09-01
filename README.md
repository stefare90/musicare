# 🎵 MusicAre
<p align="center">
  <img src="assets/images/readme_header.png" alt="MusicAre Header" width="100%">
</p>

> Music are the plugins. We are the player.

`MusicAre` is an extensible, flexible, and lightweight music playback application. The core concept is straightforward: **the host application handles the visual user interface, navigation, and playback controls, while all music metadata (tracks, albums, artists, search, playlists) and audio sources are provided by dynamic external plugins.**

The application supports two plugin ecosystems:
* **Metadata Plugins**: Compiled into `.evc` bytecode, packaged as `.zip` archives, and interpreted dynamically at runtime using `dart_eval`.
* **Audio Source Plugins**: Written in Pure-Python, packaged as `.zip` archives, and executed in the background as a local REST daemon via `serious_python` and `yt-dlp`.

---

## 🎯 Architectural Vision

The application serves as a universal, service-agnostic playback framework:
* **Separation of Responsibilities**: The host application focuses on native performance, UI, and audio playback, delegating content delivery to modular plugins.
* **Decentralized Discovery**: The application discovers community plugins on GitHub (`topic:musicare-plugin`), fetches release archives, and installs them locally.
* **Extensible & Updatable**: Plugins reside in local storage and can be updated over the air without requiring a full application release.

---

## 🏗️ System Architecture

MusicAre follows a decoupled, Feature-First Clean Architecture organized into well-defined layers:

```text
┌────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                    │
│           (UI Pages, Widgets, &  Navigation)           │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                 STATE MANAGEMENT LAYER                 │
│                                                        │
│ ┌──────────────────────┐      ┌──────────────────────┐ │
│ │ LOCAL STATE MACHINES │      │GLOBAL STATE MACHINES │ │
│ │ (Screen-Level Cubit) │ ◄────│ (Global Cubits, e.g. │ │
│ │ (es. Home, Search)   │      │  PluginCubit, Player)│ │
│ └──────────┬───────────┘      └──────────┬───────────┘ │
└────────────┼─────────────────────────────┼─────────────┘
                     │                             │
                     ▼                             ▼
┌────────────────────────────────────────────────────────┐
│                  SERVICES LAYER (IoC)                  │
│                                                        │
│  * PluginEngine (Bytecode VM manager & SemVer check)   │
│  * AudioSourceEngine (serious_python local REST daemon)│
│  * PluginDiscoveryService (GitHub plugin search)       │
│  * PreferencesService (Native host settings)           │
│  * NetworkService (Native host HTTP client)            │
│  * SDK Adapters (PluginNetwork, PluginStorage, UI)     │
└──────────────────────────┬─────────────────────────────┘
                           │ (Contract Injection)
                           ▼
┌────────────────────────────────────────────────────────┐
│                    PLUGIN EXECUTION                    │
├────────────────────────────┬───────────────────────────┤
│     METADATA PLUGINS       │   AUDIO SOURCE PLUGINS    │
│  (dart_eval Interpreter)   │ (serious_python + Flask)  │
└────────────────────────────┴───────────────────────────┘
```

### Layer Responsibilities

1. **Presentation Layer (UI & Navigation)**: Composed of UI pages, reusable widgets, and `GoRouter` declarative navigation configurations (such as the persistent shell and mini-player).
2. **State Management Layer (Cubits & Blocs)**:
   * **Global Cubits**: App-level singletons managing cross-cutting state (e.g., active plugin lifecycle, global audio player state).
   * **Local Cubits**: Screen-scoped state machines instantiated for specific pages and destroyed when navigating away.
3. **Services Layer (IoC / Dependency Injection)**: Houses central application services registered in `GetIt`, including host storage, native network clients, GitHub discovery, dynamic `PluginEngine`, and `AudioSourceEngine`.
4. **Plugin Sandbox Layer**: Sandboxed execution environments:
   * **Metadata**: Runs interpreted `.evc` bytecode via `dart_eval`.
   * **Audio Source**: Runs local background daemon with ephemeral port via `serious_python`, resolving candidate streams via localhost `POST /get_stream`.

---

## 📁 Project Directory Structure

```text
lib/
├── core/                           # Shared core infrastructure, routing, DI, and host services
│   ├── di/                         # Service locator configuration (GetIt)
│   ├── l10n/                       # Localization and translations (.arb)
│   ├── router/                     # Navigation rules and router configuration (GoRouter)
│   ├── services/                   # Native I/O host services (NetworkService, PreferencesService)
│   └── theme/                      # Styling and design system
│
└── features/                       # Modular vertical feature slices (Feature-First)
    ├── plugin/                     # Dynamic plugin subsystem (Metadata & Audio Source engines)
    │   ├── data/                   # Feature data layer (Engines, models, and services)
    │   │   ├── exceptions/         # Feature-specific exception classes
    │   │   ├── models/             # Data models and JSON entities
    │   │   └── services/           # Data services, engines, and discovery
    │   │
    │   └── presentation/           # Feature presentation layer
    │       ├── cubit/              # State management machines (Cubits & States)
    │       └── pages/              # User interface pages and graphical screens
    │
    └── [other_features]/           # Domain features (e.g. shell, home, search, library, player)
```

---

## 🗺️ Project Roadmap

To track progressive implementation milestones and upcoming tasks, please refer to the [Implementation Roadmap](documents/ROADMAP.md).