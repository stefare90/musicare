# 🗺️ MusicAre - Implementation Roadmap

This roadmap tracks the step-by-step implementation of the MusicAre application framework and its integration with the dynamic plugin subsystem.

---

## 📦 Phase 1: Project Setup & Package Configurations
*   [x] Initialize the Flutter project as `MusicAre`
*   [x] Design and create the encapsulated directory structure
*   [x] Add required dependencies to `pubspec.yaml` (GetIt, flutter_bloc, go_router, shared_preferences, dart_eval, archive, path, path_provider, pub_semver)
*   [x] Link the official SDK repository via Git dependency
*   [ ] Configure the native localization generator and create basic `.arb` files

## 🔌 Phase 2: Host SDK Services (`lib/features/plugin/data/services/sdk_services/`)
*   [x] Implement `PluginNetworkService` (using `package:http` with rate-limiting delay and tests)
*   [x] Implement `PluginStorageService` (using `shared_preferences` with prefix isolation and unit tests)
*   [x] Implement `PluginUiService` (using native dynamic form dialogs and widget integration tests)

## ⚙️ Phase 3: Dependency Injection & Routing (`lib/core/`)
*   [x] Configure `GoRouter` with `StatefulShellRoute` in `app_router.dart` exposing `rootNavigatorKey` for persistent player navigation
*   [x] Configure GetIt in `injection.dart` to register host services (`INetworkService`, `IStorageService`, `IUIService`) as singletons
*   [x] Add `PreferencesService` and `NetworkService` native host infrastructure abstractions in `lib/core/` with unit tests

## 🧠 Phase 4: Plugin Engine & Discovery (`lib/features/plugin/data/`)
*   [x] Implement `PluginEngine` to handle zip extraction, SemVer compatibility checks, local disk persistence, and `dart_eval` VM execution
*   [x] Implement `PluginDiscoveryService` to search community plugins on GitHub (`topic:musicare-plugin`) and extract release manifests
*   [x] Add unit tests for `PluginEngine` and `PluginDiscoveryService`

## 📊 Phase 5: State Management (`lib/features/plugin/presentation/cubit/`)
*   [x] Define `PluginState` machine states (Initial, Loading, NotConfigured, Loaded, Error)
*   [x] Implement `PluginCubit` for active plugin lifecycle, disk recovery, installation, and authentication
*   [x] Implement `PluginDiscoveryCubit` for online community plugin discovery
*   [x] Add unit tests for `PluginCubit` and `PluginDiscoveryCubit`

## 🖥️ Phase 6: UI Integration & Verification (`lib/features/home/presentation/` & `main.dart`)
*   [ ] Configure `main.dart` with `MultiBlocProvider` (`PluginCubit` and `PluginDiscoveryCubit`)
*   [ ] Add translation and string management
*   [ ] Implement `PluginSelectionPage` (Onboarding UI for GitHub community plugin selection and local zip import)
*   [ ] Implement `HomePage` and `HomeCubit` to fetch and render dynamic browse sections
*   [ ] Conduct the first E2E integration verification (verifying dynamic section rendering)