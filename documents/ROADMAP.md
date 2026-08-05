# 🗺️ MusicAre - Detailed Implementation Roadmap

This roadmap tracks the step-by-step implementation of the MusicAre application framework and its integration with the dynamic plugin subsystem.

---

## 📦 Phase 1: Project Setup & Package Configurations
*   [x] Initialize the Flutter project as `MusicAre`
*   [x] Design and create the encapsulated directory structure
*   [x] Add required dependencies to `pubspec.yaml` (GetIt, flutter_bloc, go_router, shared_preferences, dart_eval, archive, path, path_provider, pub_semver)
*   [x] Link the official SDK repository via Git dependency
*   [x] Configure the native localization generator and create basic `.arb` files

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

## 📊 Phase 5: Plugin State Management (`lib/features/plugin/presentation/cubit/`)
*   [x] Define `PluginState` machine states (Initial, Loading, NotConfigured, Loaded, Error)
*   [x] Implement `PluginCubit` for active plugin lifecycle, disk recovery, installation, and authentication
*   [x] Implement `PluginDiscoveryCubit` for online community plugin discovery
*   [x] Add unit tests for `PluginCubit` and `PluginDiscoveryCubit`

## 🖥️ Phase 6: Home & Dynamic Core UI (`lib/features/home/` & `lib/core/`)
*   [x] Configure `main.dart` with `BlocProvider` (`PluginCubit`)
*   [x] Add translation and string management
*   [x] Add theme management
*   [x] Implement `PluginSelectionPage` (Onboarding UI for GitHub community plugin selection)
*   [x] Implement `HomeCubit` & `HomeState` to fetch dynamic browse sections (`IBrowse`) with pull-to-refresh
*   [x] Create reusable core UI components: `MediaCard`, `MediaCoverImage`, `SectionRow`, `InfoCard`, `ErrorCard`, `EmptyView`
*   [x] Create pure Dart `MediaItemMetadata` model, `MediaType` enum, `unboxMediaItem` utility, and `MediaTypeLocalizer`
*   [x] Add unit and widget tests for Home, Core Widgets, and `MediaItemMetadata`

## 🎵 Phase 7: Media Navigation & Detail System (`lib/features/details/`)
*   [ ] **Shared UI Slivers (`lib/core/widgets/`)**:
    *   [x] Implement `mediaItem.open(context)` navigation extension (`lib/core/router/media_navigation_extension.dart`)
    *   [x] Implement `TrackListTile` for vertical track lists & tests
    *   [x] Implement `SliverMediaHeader` (collapsible header with cover image, gradient, title, subtitle, and action buttons) & tests
    *   [x] Implement `SliverTrackList` (reusable sliver list wrapper for tracks with pagination spinner) & tests
*   [ ] **Navigation & Routing**:
    *   [ ] Register `/playlist`, `/album`, and `/artist` routes in `app_router.dart`
*   [ ] **Playlist Detail Feature (`lib/features/details/`)**:
    *   [ ] Implement `PlaylistCubit` & `PlaylistState` (fetching playlist tracks) and unit tests
    *   [ ] Implement `PlaylistPage` UI using `SliverMediaHeader` & `SliverTrackList`
*   [ ] **Album Detail Feature (`lib/features/details/`)**:
    *   [ ] Implement `AlbumCubit` & `AlbumState` (fetching album tracks) and unit tests
    *   [ ] Implement `AlbumPage` UI using `SliverMediaHeader` & `SliverTrackList`
*   [ ] **Artist Detail Feature (`lib/features/details/`)**:
    *   [ ] Implement `ArtistCubit` & `ArtistState` (fetching artist top tracks & albums) and unit tests
    *   [ ] Implement `ArtistPage` UI using `SliverMediaHeader`, `SliverTrackList`, and `SectionRow` (Discography)

## 🔍 Phase 8: Search Feature (`lib/features/search/`)
*   [ ] **State Management**:
    *   [ ] Define `SearchState` (Initial, Loading, Loaded, Error)
    *   [ ] Implement `SearchCubit` for debounced query execution via `pluginEngine.metadata.search`
    *   [ ] Implement search filter chips (Tracks, Albums, Artists, Playlists) via `ISearch.chips()`
*   [ ] **Presentation**:
    *   [ ] Implement `SearchPage` UI (Search bar, Chip row, polymorphic results using `TrackListTile` & `MediaCard`)
    *   [ ] Add unit and widget tests for `SearchCubit` and `SearchPage`

## 📚 Phase 9: Library & User Library Feature (`lib/features/library/`)
*   [ ] **Authentication & Profile**:
    *   [ ] Integrate plugin authentication flow (`pluginEngine.metadata.auth.authenticate()`)
    *   [ ] Fetch and display user profile details (`IUser.me()`)
*   [ ] **State Management**:
    *   [ ] Implement `LibraryCubit` and `LibraryState` to fetch saved tracks, albums, artists, and playlists (`IUser`)
*   [ ] **Presentation**:
    *   [ ] Implement `LibraryPage` UI (Categorized tabbed view for Playlists, Albums, Artists, Saved Songs)
    *   [ ] Add unit and widget tests for `LibraryCubit` and `LibraryPage`

## 🎧 Phase 10: Audio Player & Playback Engine (`lib/features/player/`)
*   [ ] **Playback Architecture**:
    *   [ ] Define Audio Source plugin contract & audio playback service adapter
    *   [ ] Implement `PlayerCubit` & `PlayerState` (active track, play/pause, seek, queue, repeat, shuffle)
*   [ ] **Presentation**:
    *   [ ] Expand persistent mini-player in `ShellPage` (active track cover, progress bar, play/pause, skip)
    *   [ ] Implement `FullPlayerPage` (large cover art, lyrics view, queue manager, audio controls)
    *   [ ] Add unit and widget tests for `PlayerCubit` and player widgets

## 🛠️ Phase 11: Advanced Features, Refactorings & Pending Tasks
*   [ ] Implement mosaic image generator for playlists without a default cover image
*   [ ] Add local disk caching for metadata responses and cover art
*   [ ] Implement Settings page (active plugin management, theme switching, storage clearing)