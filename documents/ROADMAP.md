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

## 🔄 Phase 8: Plugin Architecture Segmentation & Metadata Renaming (`lib/features/plugin/`)
*   [x] **Shared Module (`lib/features/plugin/shared/`)**:
    *   [x] Create `shared/data/models/` (`PluginType` enum and `PluginManifest` with `pluginType` getter)
    *   [x] Create `shared/data/exceptions/` (`PluginException` base classes)
    *   [x] Create `shared/presentation/utils/` (`ExceptionLocalizer` extension)
*   [x] **Discovery Module (`lib/features/plugin/discovery/`)**:
    *   [x] Move `PluginDiscoveryService` to `discovery/data/services/` with in-memory `PluginType` filtering
    *   [x] Move `PluginDiscoveryCubit` / `PluginDiscoveryState` to `discovery/presentation/cubit/`
    *   [x] Move `PluginDiscoveryWidget` to `discovery/presentation/widgets/` (supporting optional `pluginType` filter parameter)
*   [x] **Metadata Subsystem Renaming (`lib/features/plugin/metadata/`)**:
    *   [x] Move metadata engine and SDK host adapters to `metadata/data/services/`
    *   [x] Rename `PluginEngine` to `MetadataPluginEngine`
    *   [x] Move cubits to `metadata/presentation/cubit/` and rename `PluginCubit` / `PluginState` to `MetadataPluginCubit` / `MetadataPluginState`
    *   [x] Move update page to `metadata/presentation/pages/metadata_plugin_update_page.dart`
    *   [x] Update local disk storage isolation to `plugins/metadata/<id>/`
    *   [x] Update DI in `injection.dart`, router, page usages, and all test suites

## 🐍 Phase 9: Audio Source Subsystem Architecture & SDK Decoupling
*   [x] **Standalone SDK Monorepo (`musicare_audiosource_sdk`)**:
    *   [x] Implement `python/plugin_sdk/` (`musicare-plugin-sdk`): domain contracts (`Track`, `AudioStreamResponse`), `BaseAudioSourcePlugin`, `TrackMatcher`, and CLI tools (`musicare-build`, `musicare-play`)
    *   [x] Implement `python/host_runtime/`: persistent Flask daemon with dynamic `importlib.util.spec_from_file_location` plugin loader
    *   [x] Implement `dart/host_sdk/` (`musicare_dart_host_sdk`): `AudioSourceClient` managing SeriousPython lifecycle, ephemeral port binding, dynamic plugin injection (`/load_plugin`), and stream resolution (`/get_stream`)
    *   [x] Implement `dart/harness/`: automated E2E compliance test harness validating unzipped plugins on Android and Linux desktop
*   [x] **Official Template Plugin (`musicare_audiosource_youtube_plugin`)**:
    *   [x] Implement 100% pure-Python YouTube audio source provider using `yt-dlp` and `certifi`
    *   [x] Add offline unit tests and live E2E CDN Range handshake tests
*   [x] **Host Application Refactoring (`music_are`)**:
    *   [x] Add `musicare_dart_host_sdk` dependency via Git
    *   [x] Implement `tool/build_python.sh` for staging and compiling SeriousPython host runtime
    *   [x] Refactor `AudioSourcePluginEngine` to eliminate fragile `runProgram` re-boots, delegating to `AudioSourceClient`
    *   [x] Remove duplicate local models and unify DI in `injection.dart`
    *   [x] Successfully verify dynamic plugin download, unpacking, and runtime injection on Android 15 hardware (Moto G84)

## 🧙‍♂️ Phase 10: Step-by-Step Onboarding Wizard (`lib/features/onboarding/`)
*   [x] **Wizard Flow**:
    *   [x] Refactor `WelcomePage` into a multi-step onboarding wizard:
        *   **Step 1**: Select & install Metadata Provider (`MetadataPluginCubit`)
        *   **Step 2**: Select & install Audio Source Provider (`AudioSourcePluginCubit`)
    *   [x] Navigate to Home (`/`) once both subsystems are configured
    *   [x] Add widget tests for multi-step onboarding flow

## 🎧 Phase 11: Audio Player & Playback Engine (`lib/features/player/`)

### 11.1. Native Audio Infrastructure & Service Layer
*   [x] **Dependencies Setup**:
    *   [x] Add `just_audio` and `just_audio_background` to `pubspec.yaml`
*   [x] **Android Platform Configuration**:
    *   [x] Configure `AndroidManifest.xml` with permissions (`INTERNET`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS` for Android 13+)
    *   [x] Enable `android:usesCleartextTraffic="true"` for local proxy/stream playback
    *   [x] Declare `AudioService` and `MediaButtonReceiver` in manifest
    *   [x] Configure main activity with `com.ryanheise.audioservice.AudioServiceActivity`
*   [x] **Audio Service Layer & Background Setup**:
    *   [x] Initialize `JustAudioBackground.init(...)` with notification channel, icon, and ongoing parameters in `main.dart`
    *   [x] Implement `AudioPlayerService` wrapper around `AudioPlayer` isolating hardware playback, streams, and controls
    *   [x] Register `AudioPlayerService` in GetIt (`injection.dart`)
    *   [x] Verified on real Android hardware (Moto G84, Android 15) with native notification, lock screen controls, and background playback

### 11.2. Stream Resolution & Candidate Fallback Service
*   [x] **Models & Resolution Service**:
    *   [x] Implement `ResolvedPlaybackTrack` model with candidate tracking, fallback navigation, and `expiresAt` expiration check
    *   [x] Implement `AudioStreamResolver` querying `AudioSourcePluginEngine.resolveStream()` and generating `AudioSource` with HTTP headers (`User-Agent`, etc.) and `MediaItem` tag
    *   [x] Unit tests for `ResolvedPlaybackTrack` (`test/features/player/data/models/resolved_playback_track_test.dart`)
    *   [x] Unit tests for `AudioStreamResolver` (`test/features/player/data/services/audio_stream_resolver_test.dart`)

### 11.3. Player State Management & Queue Model (`lib/features/player/presentation/cubit/`)
*   [x] **Queue Domain Model**:
    *   [x] Implement `PlaybackQueue` model and `RepeatMode` enum (`off`, `all`, `one`) with shuffle and queue manipulation logic
    *   [x] Unit tests for `PlaybackQueue` (`test/features/player/data/models/playback_queue_test.dart`)
*   [x] **State & Cubit Integration**:
    *   [x] Integrate `PlaybackQueue` into `PlayerState` and `PlayerCubit`
    *   [x] Implement queue navigation commands (`next()`, `previous()`, `skipToIndex()`)
    *   [x] Implement auto-advance on track playback completion
    *   [x] Implement candidate retry/fallback on network or CDN failure during `setAudioSource`
    *   [x] Expose repeat mode cycling and shuffle toggling
    *   [x] Comprehensive unit tests for `PlayerCubit` with queue operations

### 11.4. Presentation: Persistent Mini-Player (`lib/features/player/presentation/widgets/`)
*   [x] **MiniPlayer Widget**:
    *   [x] Basic `MiniPlayer` layout in `ShellPage` (thumbnail, title, artist, progress bar, play/pause toggle)
    *   [x] Add skip next button
    *   [x] Add tap gesture to open full-screen player modal
    *   [x] Widget tests for `MiniPlayer`
    *   [x] Add swipe to open mini player
    *   [x] Add back button in mini player

### 11.5. Presentation: Full-Player Modal Sheet (`lib/features/player/presentation/pages/`)
*   [ ] **FullPlayerPage UI**:
    *   [ ] Full-screen draggable modal bottom sheet with smooth transition
    *   [ ] Large cover art, title, artists with navigation
    *   [ ] Interactive scrubber / slider with current position and duration labels
    *   [ ] Playback control row: Shuffle, Previous, Play/Pause, Next, Repeat
    *   [ ] Stream quality badge and queue button
*   [ ] **QueueBottomSheet**:
    *   [ ] Reorderable queue view (`ReorderableListView`) with swipe-to-remove
*   [ ] **Widget Tests**:
    *   [ ] Widget tests for `FullPlayerPage` and `QueueBottomSheet`

### 11.6. Global App Integration & Media Tap Wiring
*   [ ] **App-wide Playback Integration**:
    *   [ ] Connect tap-to-play with context queue on `AlbumPage`, `PlaylistPage`, `ArtistPage`
    *   [ ] Active track visual indicator on all lists (`isPlaying`)
    *   [ ] Wire "Add to Queue" option in `TrackOptionsBottomSheet`

### 11.7. Test Suite (`test/features/player/`)
*   [ ] **Unit Tests**:
    *   [ ] `AudioStreamResolverTest`: test di fallback sui candidati alternativi in caso di errore 403 o eccezione del primo stream.
    *   [ ] `PlayerCubitTest`: test del ciclo di vita completo (play, pause, next, prev, repeat modes, shuffle, gestione coda, seek).
*   [ ] **Widget Tests**:
    *   [ ] `MiniPlayerTest`: verifica rendering, cambi di stato play/pause, tap per apertura full player, barra di avanzamento.
    *   [ ] `FullPlayerPageTest`: verifica controlli, slider seek, visualizzazione metadati e apertura coda.

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
