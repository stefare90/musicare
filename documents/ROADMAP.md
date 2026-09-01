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
*   [x] **Shared UI Slivers (`lib/core/widgets/`)**:
    *   [x] Implement `mediaItem.open(context)` navigation extension (`lib/core/router/media_navigation_extension.dart`)
    *   [x] Implement `TrackListTile` for vertical track lists & tests
    *   [x] Implement `SliverMediaHeader` (collapsible header with cover image, gradient, title, subtitle, and action buttons) & tests
    *   [x] Implement `SliverTrackList` (reusable sliver list wrapper for tracks with pagination spinner) & tests
*   [x] **Navigation & Routing**:
    *   [x] Register `/playlist`, `/album`, and `/artist` routes in `app_router.dart`
*   [x] **Playlist Detail Feature (`lib/features/details/`)**:
    *   [x] Implement `PlaylistCubit` & `PlaylistState` (fetching playlist tracks) and unit tests
    *   [x] Implement `PlaylistPage` UI using `SliverMediaHeader` & `SliverTrackList`
*   [x] **Album Detail Feature (`lib/features/details/`)**:
    *   [x] Implement `AlbumCubit` & `AlbumState` (fetching album tracks) and unit tests
    *   [x] Implement `AlbumPage` UI using `SliverMediaHeader` & `SliverTrackList`
*   [x] **Artist Detail Feature (`lib/features/details/`)**:
    *   [x] Implement `ArtistCubit` & `ArtistState` (fetching artist top tracks & albums) and unit tests
    *   [x] Implement `ArtistPage` UI using `SliverMediaHeader`, `SliverTrackList`, and `SectionRow` (Discography)

## 🔄 Phase 8: Metadata Plugin Renaming & Architecture Segmentation (`lib/features/plugin/`)
*   [ ] **Core Domain & Unified Discovery**:
    *   [ ] Create `lib/features/plugin/core/` with `PluginType` enum (`metadata`, `audioSource`), `PluginManifest`, and shared exception classes
    *   [ ] Update `PluginDiscoveryService` to support in-memory filtering by `PluginType` using single GitHub search (`topic:musicare-plugin`)
*   [ ] **Metadata Subsystem Renaming**:
    *   [ ] Move metadata files to `lib/features/plugin/metadata/`
    *   [ ] Rename `PluginEngine` to `MetadataPluginEngine`
    *   [ ] Rename `PluginCubit` / `PluginState` to `MetadataPluginCubit` / `MetadataPluginState`
    *   [ ] Update local disk storage isolation to `plugins/metadata/<id>/`
    *   [ ] Update DI registrations in `injection.dart`, router, page usages, and all test suites

## 🐍 Phase 9: Audio Source Plugin Engine & Subsystem (`lib/features/plugin/audio_source/`)
*   [ ] **Dependencies & Models**:
    *   [ ] Add `serious_python` dependency to `pubspec.yaml`
    *   [ ] Define `AudioStreamResponse` (url, quality, bitrate, codec, expiresAt, headers) and `AudioQuality` enum (`low`, `medium`, `high`)
*   [ ] **Lifecycle & Daemon Engine**:
    *   [ ] Implement ephemeral port allocator helper (`getUnusedPort`)
    *   [ ] Implement `AudioSourcePluginEngine`: `.zip` extraction, local disk persistence in `plugins/audio_source/<id>/`, background Python daemon spawn/terminate via `serious_python`
    *   [ ] Implement readiness polling mechanism (`GET /ping` health-check)
*   [ ] **REST IPC Client**:
    *   [ ] Implement `AudioSourceClient`: execute `POST /get_stream` on `127.0.0.1:$PORT` serializing `Track` payload
    *   [ ] Parse candidate stream list and handle fallback heuristics
*   [ ] **State Management**:
    *   [ ] Implement `AudioSourcePluginCubit` & `AudioSourcePluginState` (Initial, Loading, NotConfigured, Loaded, Error)
    *   [ ] Persist active audio source ID in `PreferencesService` (`active_audio_source_plugin_id`)
*   [ ] **Testing**:
    *   [ ] Add unit tests for `AudioSourcePluginEngine`, `AudioSourceClient`, and `AudioSourcePluginCubit` with mocktail HTTP client

## 🧙‍♂️ Phase 10: Step-by-Step Onboarding Wizard (`lib/features/onboarding/`)
*   [ ] **Wizard Flow**:
    *   [ ] Refactor `WelcomePage` into a multi-step onboarding wizard:
        *   **Step 1**: Select & install Metadata Provider (`MetadataPluginCubit`)
        *   **Step 2**: Select & install Audio Source Provider (`AudioSourcePluginCubit`)
    *   [ ] Navigate to Home (`/`) once both subsystems are configured
    *   [ ] Update `PluginUpdatePage` to support recovery for both metadata and audio source incompatibility
    *   [ ] Add widget tests for multi-step onboarding flow

## 🎧 Phase 11: Audio Player & Playback Engine (`lib/features/player/`)
*   [ ] **Core Audio Service & Platform Handler**:
    *   [ ] Integrate native playback engine (e.g. `just_audio` + `audio_service`)
    *   [ ] Implement background audio playback, lock screen media controls, and audio focus management
*   [ ] **Player State Management**:
    *   [ ] Implement `PlayerCubit` & `PlayerState` (active track, play/pause, buffering, seek position, playback queue, repeat, shuffle)
    *   [ ] Automatic stream resolution via `AudioSourceClient` on track change with transparent fallback to candidate #2 if primary stream fails
*   [ ] **Presentation**:
    *   [ ] Expand persistent Mini-Player in `ShellPage` (cover art, track title, artist, progress indicator, play/pause, skip)
    *   [ ] Implement `FullPlayerPage` modal/sheet (large artwork, interactive scrub slider, playback controls, stream quality badge, reorderable queue manager)
*   [ ] **Testing**:
    *   [ ] Add unit and widget tests for `PlayerCubit`, `MiniPlayer`, and `FullPlayerPage`

## 🔍 Phase 12: Search Feature (`lib/features/search/`)
*   [ ] **State Management**:
    *   [ ] Define `SearchState` (Initial, Loading, Loaded, Error)
    *   [ ] Implement `SearchCubit` for debounced query execution via `metadataPluginEngine.metadata.search`
    *   [ ] Implement search filter chips (Tracks, Albums, Artists, Playlists) via `ISearch.chips()`
*   [ ] **Presentation**:
    *   [ ] Implement `SearchPage` UI (Search bar, Chip row, polymorphic results using `TrackListTile` & `MediaCard`)
    *   [ ] Add unit and widget tests for `SearchCubit` and `SearchPage`

## 📚 Phase 13: Library & User Library Feature (`lib/features/library/`)
*   [ ] **Authentication & Profile**:
    *   [ ] Integrate plugin authentication flow (`metadataPluginEngine.metadata.auth.authenticate()`)
    *   [ ] Fetch and display user profile details (`IUser.me()`)
*   [ ] **State Management**:
    *   [ ] Implement `LibraryCubit` and `LibraryState` to fetch saved tracks, albums, artists, and playlists (`IUser`)
*   [ ] **Presentation**:
    *   [ ] Implement `LibraryPage` UI (Categorized tabbed view for Playlists, Albums, Artists, Saved Songs)
    *   [ ] Add unit and widget tests for `LibraryCubit` and `LibraryPage`

## 🛠️ Phase 14: Advanced Features, Refactorings & Polish
*   [ ] Implement mosaic image generator for playlists without a default cover image
*   [ ] Add local disk caching for metadata responses and cover art
*   [ ] Implement Settings page (active metadata and audio source plugin management, cache clearing, theme selection)

## To Fix Now

## To Fix Later
*   [ ] Fast up media cover image show
*   [ ] Fix media cover image sometimes don't appear
*   [ ] manage http request to be compliant with used api (to manage in sdk)
*   [ ] Improve Fans Like Also to avoid exceptions 
*   [ ] Add artist list e album name in bottom modal options
*   [ ] Manage orizontal layout |===|
*   [ ] Add Favorites function to Artists, Albums and Songs
*   [ ] Improve Top Tracks to retrieve true top tracks basing on listenbrainz instead musicbrainz