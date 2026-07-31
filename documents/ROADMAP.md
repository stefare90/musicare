# 🗺️ MusicAre - Implementation Roadmap

This roadmap tracks the step-by-step implementation of the MusicAre application framework and its integration with the dynamic plugin subsystem.

---

## 📦 Phase 1: Project Setup & Package Configurations
*   [x] Initialize the Flutter project as `MusicAre`
*   [x] Design and create the improved, encapsulated directory structure
*   [x] Add required dependencies to `pubspec.yaml` (GetIt, flutter_bloc, go_router, shared_preferences, dart_eval)
*   [x] Link the official SDK repository via Git dependency
*   [ ] Create the `assets/` folder, place `plugin.evc` inside, and register it in `pubspec.yaml`
*   [ ] Configure the native localization generator and create basic `.arb` files

## 🔌 Phase 2: Host SDK Services (`lib/features/plugin/data/services/`)
*   [x] Implement `PluginNetworkService` (using `package:http` with a 1-second rate-limiting delay and tests)
*   [x] Implement `StorageService` (using `shared_preferences` with a safe prefix/namespace and unit tests)
*   [x] Implement `PluginUiService` (using native Flutter dynamic dialogs injected with `GlobalKey<NavigatorState>` and widget integration tests)

## ⚙️ Phase 3: Dependency Injection & Routing (`lib/core/`)
*   [x] Configure `GoRouter` with `StatefulShellRoute` in `app_router.dart` exposing `rootNavigatorKey` for persistent player navigation
*   [x] Configure GetIt in `injection.dart` to register host services (`INetworkService`, `IStorageService`, `IUIService`) as singletons

## 🧠 Phase 4: The Plugin Manager (`lib/features/plugin/data/`)
*   [x] Implement `PluginManager` to load `plugin.evc`, register the SDK bridge, and execute the plugin entry point

## 📊 Phase 5: State Management (`lib/features/plugin/presentation/cubit/`)
*   [x] Define the `PluginState` machine states (Initial, Loading, Loaded, Error)
*   [X] Implement `PluginCubit` to manage async loading states and communicate with the UI
*   [ ] Add UnitTests
*   [ ] Update and Improve Readme 

## 🖥️ Phase 6: UI Integration & Verification (`lib/features/home/presentation/` & `main.dart`)
*   [ ] Initialize DI, Cubits, and GoRouter in `main.dart`
*   [ ] Implement `HomeScreen` with `BlocBuilder` to fetch and render the plugin's home browse sections
*   [ ] Conduct the first E2E integration verification (verifying sections and items loaded dynamically)