**Hai ragionissima!** 

Il Router (`AppRouter`) fa parte dell'infrastruttura di **Navigazione ed Interfaccia Grafica (Presentation Layer)**, non è un servizio dati o di business del Service Locator. Inserirlo nella scatola dei "Servizi Globali" creava una sovrapposizione concettuale.

Inoltre, rinominare quel layer semplicemente in **`SERVICES LAYER (IoC)`** rende il diagramma molto più preciso ed esatto.

---

### 🛠️ Diagramma e `README.md` Corretti

Ecco il `README.md` con il diagramma architetturale corretto:

1. **`AppRouter`** spostato in alto nel **Presentation Layer** (dove risiede la navigazione dichiarativa di `GoRouter`).
2. **`SERVICES LAYER (IoC)`** contiene ora esclusivamente i **servizi reali** dell'app (`PluginEngine`, `PluginDiscoveryService`, `PreferencesService`, `NetworkService` e gli `SDK Adapters`).

---

`README.md`

```markdown
# 🎵 MusicAre
> Music are the plugins. We are the player.

`MusicAre` is an extensible, flexible, and lightweight music playback application. The core concept is straightforward: **the host application handles the visual user interface, navigation, and playback controls, while all music metadata (tracks, albums, artists, search, playlists) and audio sources are provided by dynamic external plugins.**

Plugins are compiled into `.evc` bytecode, packaged as compressed archives, and interpreted dynamically at runtime using `dart_eval`.

---

## 🎯 Architectural Vision

The application serves as a universal, service-agnostic playback framework:
* **Separation of Responsibilities**: The host application focuses on native performance, UI, and audio playback, delegating content delivery to modular plugins.
* **Decentralized Discovery**: The application discovers community plugins on GitHub, fetches release archives, and installs them locally.
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
│  * PluginDiscoveryService (GitHub plugin search)       │
│  * PreferencesService (Native host settings)           │
│  * NetworkService (Native host HTTP client)            │
│  * SDK Adapters (PluginNetwork, PluginStorage, UI)     │
└──────────────────────────┬─────────────────────────────┘
                           │ (Contract Injection)
                           ▼
┌────────────────────────────────────────────────────────┐
│                    PLUGIN EXECUTION                    │
│            (Dynamic interpreter dart_eval)             │
└──────────────────────────┬─────────────────────────────┘
                           │
            ┌──────────────┴──────────────┐
            ▼                             ▼
  ┌──────────────────┐          ┌──────────────────┐
  │ METADATA PLUGINS │          │AUDIO SOURCE PLUGS│
  └──────────────────┘          └──────────────────┘
```

### Layer Responsibilities

1. **Presentation Layer (UI & Navigation)**: Composed of UI pages, reusable widgets, and `GoRouter` declarative navigation configurations (such as the persistent shell and mini-player).
2. **State Management Layer (Cubits & Blocs)**:
   * **Global Cubits**: App-level singletons managing cross-cutting state (e.g., active plugin lifecycle, global audio player state).
   * **Local Cubits**: Screen-scoped state machines instantiated for specific pages and destroyed when navigating away.
3. **Services Layer (IoC / Dependency Injection)**: Houses central application services registered in `GetIt`, including host storage, native network clients, GitHub discovery, and the dynamic `PluginEngine`.
4. **Plugin Sandbox Layer**: Sandboxed execution environment running interpreted bytecode via `dart_eval` and communicating with the host through SDK bridge adapters.

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
    ├── plugin/                     # Dynamic plugin subsystem (Exemplar feature layout)
    │   ├── data/                   # Feature data layer
    │   │   ├── exceptions/         # Feature-specific exception classes
    │   │   ├── models/             # Data models and JSON entities
    │   │   └── services/           # Data services, engines, and discovery
    │   │
    │   └── presentation/           # Feature presentation layer
    │       ├── cubit/              # State management machines (Cubits & States)
    │       └── pages/              # User interface pages and graphical screens
    │
    └── [other_features]/           # Domain features (e.g. shell, home, search, library)
```

---

## 🗺️ Project Roadmap

To track progressive implementation milestones and upcoming tasks, please refer to the [Implementation Roadmap](documents/ROADMAP.md).