# 🎵 MusicAre
> Music are the plugins. We are the player.

`MusicAre` is an innovative music player designed to be completely extensible, flexible, and lightweight. The core idea is simple: the application manages the visual interface, playback controls, and the audio player (the Host), while the entire delivery of music (tracks, albums, artists, search, and playlists) is delegated to interchangeable dynamic external modules (the Plugins). 

This allows for new music sources to be added or existing ones to be updated instantly, without having to reinstall the application or wait for long release cycles on various app stores.

---

## 🎯 Purpose of the Application

The primary purpose of `MusicAre` is to provide a universal music playback framework. The application itself is not tied to any specific streaming service; instead, it defines a "contract" (the SDK) that anyone can implement by writing their own plugin.

The key strengths of this architecture are:
1.  **Unified Forces**: The application does an excellent job of audio playback and native graphical user interface, while the plugins focus solely on retrieving data and music.
2.  **Real-Time Updates**: Plugins are downloaded and interpreted by the app at runtime. If a music source changes its API, the plugin can be updated instantly on the server, and the application will continue to work without needing a full app update.

---

## 🏗️ System Architecture

The application adopts a decoupled, layered design organized by features (Feature-First). The following diagram illustrates the system's communication and control flows:

```
┌────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                    │
│      (UI / Graphical Interface and Navigation)         │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                 STATE MANAGEMENT LAYER                 │
│                                                        │
│ ┌──────────────────────┐      ┌──────────────────────┐ │
│ │ LOCAL STATE MACHINES │      │GLOBAL STATE MACHINES │ │
│ │ (Screen-Level Cubit) │ ◄────│ (Global Cubits, e.g. │ │
│ │ (es. Browse, Search) │      │  Player, AuthState)  │ │
│ └──────────┬───────────┘      └──────────┬───────────┘ │
└────────────┼─────────────────────────────┼─────────────┘
                     │                             │
                     ▼                             ▼
┌────────────────────────────────────────────────────────┐
│                  GLOBAL SERVICES (IoC)                 │
│                                                        │
│  * AppRouter (Route configuration and control)         │
│  * PluginManager (Plugin loader and interpreter)       │
│  * HostNetworkService (Real network calls)             │
│  * HostStorageService (Local data persistence)         │
│  * HostUIService (Native Dialog generator)             │
└──────────────────────────┬─────────────────────────────┘
                           │ (Contract Injection)
                           ▼
┌────────────────────────────────────────────────────────┐
│                    PLUGIN EXECUTION                    │
│            (Dynamic interpreter dart_eval)             │
└────────────────────────────────────────────────────────┘
```

### 1. Presentation Layer (UI & Navigation)
*   **Simple Interface**: Graphical widgets exclusively observe the state emitted by their local state machine to draw themselves on screen.
*   **Persistent Navigation**: Uses a declarative router to manage navigation tabs while keeping the bottom floating audio player bar persistent, active, and visible in memory during navigation between different tabs [1, 4].

### 2. State Management Layer (State Machines)
The application state is strictly divided into two categories to optimize RAM footprint and ensure maximum scalability [1]:
*   **Local State Machines (Screen-Level Cubit)**: Each screen has its own dedicated Cubit (e.g., `BrowseCubit`, `PlaylistCubit`). They are instantiated when the page opens and automatically destroyed when it closes, querying Global Services to populate the UI [1].
*   **Global State Machines (App-Level States)**: These are singleton Cubits that remain active for the entire lifetime of the application. They manage information that affects the whole app, such as `AudioPlayerCubit` (currently playing track and play/pause state) or `AuthCubit` (user session state) [1].

### 3. Global Services (IoC)
Global Services represent the infrastructural logic of the application. They are registered at startup in a centralized Service Locator (IoC GetIt) so that any module can request them without direct coupling [2, 5]. 

To maximize encapsulation and maintain a clean separation of concerns, the concrete implementations of the contracts required by the plugins' SDK are housed directly within the `plugins` feature folder rather than polluting the shared `core` directories [1]. If the plugin subsystem is ever removed, deleting the `features/plugins` folder completely wipes all plugin-related code from the host:
*   **`AppRouter`**: Centralizes the app's route map, deep links, and navigation bar with the persistent player [1, 4].
*   **`PluginManager`**: The core of the system. It handles reading the plugins' bytecode, starting the dynamic interpreter, injecting real Host Services, and returning the ready-to-use plugin interface [2, 5].
*   **`HostNetworkService`**: Implements the SDK's network interface. It translates plugin requests into real system HTTP calls, managing headers and User-Agent [3].
*   **`HostStorageService`**: Implements the SDK's persistence interface. It allows the plugin to securely and asynchronously persist session tokens or local settings on disk [1].
*   **`HostUIService`**: Implements the SDK's graphical interface. It translates plugin requests (e.g., a request to show a login form) into real native Flutter dialogs, waiting for user input and returning the entered data [1].

---

## 📁 Project Directory Tree (PoC & Scalable)

The project tree follows a Feature-First philosophy, where each feature encapsulates its own logic and presentation, while infrastructural services reside in a centralized core folder:

```text
lib/
├── core/                           # Shared core services, configurations, and utilities
│   ├── di/                         # Service Locator (IoC) setup and registration
│   │   └── injection.dart          # Centralized GetIt registrations
│   │
│   ├── l10n/                       # Translations and localization (.arb files and l10n.yaml)
│   │   ├── app_en.arb              # English translation source
│   │   └── app_it.arb              # Italian translation source
│   │
│   ├── router/                     # Declarative navigation system
│   │   └── app_router.dart         # GoRouter setup with persistent navigation Shell
│   │
│   └── theme/                      # App design system, styles, and themes
│       ├── app_colors.dart         # Global color palettes
│       ├── app_typography.dart     # Typography styles and sizes
│       └── app_theme.dart          # Light and dark Flutter theme configurations
│
└── features/                       # Vertical modular feature slices
    ├── plugins/                    # Dynamic plugin execution and management feature
    │   ├── data/                   # Domain services and dynamic loader implementations
    │   │   ├── host_services/      # Concrete host implementations of the SDK contracts
    │   │   │   ├── host_network_service.dart
    │   │   │   ├── host_storage_service.dart
    │   │   │   └── host_ui_service.dart
    │   │   │
    │   │   └── plugin_manager.dart # Loads and runs raw .evc bytecode via dart_eval
    │   │
    │   └── presentation/           # Loading indicators and plugin management UI
    │       └── cubit/              # State machine for the active plugin (Loading, Loaded, Error)
    │
    └── home/                       # Temporary presentation module (Proof of Concept)
        └── presentation/           # Home screen presentation and home Cubit
```
## 🗺️ Project Roadmap

To track our progressive implementation status and see what features are currently completed, in progress, or planned, please refer to our interactive [Roadmap](documents/ROADMAP.md).