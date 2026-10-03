# 🗺️ MusicAre — Roadmap

Legend: ✅ implemented · ⬜ to do (feature, fix or idea)

## 🧱 Foundations & core UI (`lib/core/`)
✅ Dependency injection, app preferences and native host services.
✅ Material 3 theming, localization and shared design system (card metrics, detail slivers, skeletons, bottom sheets, track matrix).

## 🖥️ Shell & navigation (`lib/features/shell/`, `lib/core/router/`)
✅ Three-tab shell (Home, Search, Library) with a dedicated navigator for the player.
✅ Persistent, draggable player panel above the shell, with mini-player and back gesture collapse.
✅ Detail routes and the incompatible-provider update route.
✅ Settings entry point (gear) on the three root tabs, opening the settings hub.

## 🏠 Home (`lib/features/home/`)
✅ Dynamic browse sections from the metadata plugin, with pull-to-refresh, per-section retry and empty/error states.

## 🔍 Search (`lib/features/search/`)
✅ Debounced global search with typed filter chips, aggregated and per-category views.
✅ Playlist results: dynamic Playlists chip from the plugin's `chips()`, per-category grid and a Playlists carousel in the aggregated view.
✅ Column-aligned pagination, contextual skeletons, scrollable empty/error states, tap on a result → playback or detail.

## 📚 Details (`lib/features/details/{album,artist,playlist}`)
✅ Album, artist and playlist pages with cover header, track list, discography, "Fans Also Like" and pagination.
✅ Contextual queue playback from any track list and save toggle in the header.
✅ Initial "saved" state read from the provider on detail pages, so the toggle reflects the real library.
✅ Remove tracks from a playlist by swiping the row, behind a confirmation dialog.

## 🎧 Player (`lib/features/player/`)
✅ Native background playback with notification, lock-screen controls and media buttons.
✅ Immutable queue with shuffle and repeat.
✅ Multi-candidate stream resolution with automatic fallback on expired streams or 403 responses.
✅ Mini-player, full player, reorderable queue sheet and live candidate switching.
⬜ Download and lyrics.
✅ "Add to queue" and "Save to favorites" wired in the track options bottom sheet (with the real saved state and optimistic rollback).

## 📚 Library (`lib/features/library/`)
✅ Sign-in invitation when signed out, with the account entry point in the page header.
✅ Saved-content tabs (playlists, albums, artists) with pagination, empty/error states and a pinned *Liked Songs* list backed by the provider, reloaded reactively when the saved set changes.
✅ Create a playlist from the library's Playlists tab, with the new entry appearing without a manual refresh.
✅ Global saved-media state (per-type IDs + optimistic toggle) and "Add to playlist" picker with a create-and-add flow.
⬜ Downloads: browse and manage local tracks and downloaded collections, account-free (entry point only, empty until the local storage subsystem lands).

## ⚙️ Settings (`lib/features/settings/`)
✅ Settings hub with a Plugins section: the active metadata and audio-source plugins with their versions, and a per-plugin detail page (version and, when the plugin exposes authentication, the account).
⬜ Remaining sections: audio quality, playback, downloads and cache, appearance (theme/language), listening history, diagnostics, about.
⬜ Per-plugin actions: update, reinstall, uninstall, change plugin.

## 🧙 Onboarding (`lib/features/onboarding/`)
✅ Step wizard: intro, metadata provider install, audio source provider install, landing on Home once both are ready.

## 🔌 Plugin system (`lib/features/plugin/{shared,discovery,metadata}` + host adapters)
✅ Community plugin discovery from GitHub releases and in-app install/update.
✅ Metadata plugin engine over the Python wire protocol (`musicare_metadata_host_sdk`), with SemVer compatibility checks and per-plugin persistence.
✅ Host-side login form for metadata plugins (`MetadataAuthPresenter`), rendering the plugin-provided title, message and per-field help link; browser-based auth opens in the system browser (`url_launcher`).
✅ In-app sign-in/sign-out under Settings → Plugins (per-plugin account), with contextual sign-in prompts when a request needs authentication (rendered as a normal state, not an error) and the affected surfaces refreshing on auth change.

## 🐍 Audio source subsystem (`lib/features/plugin/audio_source/`, `tool/build_python.sh`)
✅ Embedded CPython daemon (`serious_python`) hosting both subsystems as two Flask apps on separate ephemeral ports, with hot plugin loading.
✅ Audio source plugin engine over the wire protocol (`musicare_audio_host_sdk`), with candidate search and just-in-time stream resolution.
✅ Reproducible staging script with explicit artifact verification.
✅ Verified on Android 15 hardware (Moto G84).

## 🖼️ Cache & covers
✅ On-disk image cache and 2×2 playlist mosaic when at least two covers are available.
⬜ Local cache for metadata responses and cover warm-up.
⬜ 2×2 mosaic built from track covers when a playlist has no image.

## 🛠️ Backlog (fixes and ideas, not yet approved)
⬜ Fix a cover occasionally missing on the first cold load.
⬜ Speed up cover rendering and cache warm-up.
⬜ Rate limiting of HTTP requests towards third-party APIs (SDK level).
⬜ Better "Fans Also Like" fallback when artist data is sparse.
⬜ Show artist and album name in the track options bottom sheet.
⬜ Track favorites and a unified saved-content view.
✅ Real artist top tracks via ListenBrainz instead of work metadata.
⬜ Bluetooth next/prev buttons.
⬜ "Play all" when the playlist is only partially loaded.
