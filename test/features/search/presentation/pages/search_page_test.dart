import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/media/media_card.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/media/section_row.dart';
import 'package:music_are/core/widgets/media/track_list_tile.dart';
import 'package:music_are/core/widgets/settings_button.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_media_grid.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_search_all.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/notice_listener.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';
import 'package:music_are/features/search/presentation/pages/search_page.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

class MockMetadataPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockISearch extends Mock implements ISearch {}

class MockPlayerCubit extends Mock implements PlayerCubit {}

void main() {
  late MockMetadataPluginEngine mockEngine;
  late MockMetadataPlugin mockMetadata;
  late MockISearch mockSearch;
  late MockPlayerCubit mockPlayerCubit;

  final dummyTrack = Track(
    id: 't1',
    name: 'Yellow',
    externalUri: '',
    artists: [Artist(id: 'a1', name: 'Coldplay', externalUri: '')],
    album: Album(
      id: 'al1',
      name: 'Parachutes',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 10,
      albumType: AlbumType.album,
    ),
    durationMs: 269000,
  );

  final dummyResponse = SearchResponse(
    tracks: [dummyTrack],
    albums: [
      Album(
        id: 'al1',
        name: 'Parachutes',
        artists: [],
        releaseDate: '',
        externalUri: '',
        totalTracks: 10,
        albumType: AlbumType.album,
      ),
    ],
    artists: [Artist(id: 'a1', name: 'Coldplay', externalUri: '')],
    playlists: [],
  );

  final dummyArtist = Artist(id: 'ar1', name: 'Coldplay', externalUri: '');

  final dummyPlaylist = Playlist(
    id: 'pl1',
    name: 'Parachutes Era',
    description: '',
    externalUri: '',
    owner: User(id: 'u1', name: 'Someone', externalUri: ''),
  );

  setUp(() {
    mockEngine = MockMetadataPluginEngine();
    mockMetadata = MockMetadataPlugin();
    mockSearch = MockISearch();
    mockPlayerCubit = MockPlayerCubit();

    when(() => mockEngine.hasMetadata).thenReturn(true);
    when(() => mockEngine.metadata).thenReturn(mockMetadata);
    when(() => mockMetadata.search).thenReturn(mockSearch);
    when(() => mockSearch.chips()).thenAnswer(
      (_) async => const [
        SearchCategory.tracks,
        SearchCategory.albums,
        SearchCategory.artists,
      ],
    );
    when(() => mockSearch.all(any())).thenAnswer((_) async => dummyResponse);

    when(() => mockPlayerCubit.state).thenReturn(const PlayerState());
    when(() => mockPlayerCubit.stream).thenAnswer((_) => const Stream.empty());

    if (sl.isRegistered<MetadataPluginEngine>()) {
      sl.unregister<MetadataPluginEngine>();
    }
    sl.registerSingleton<MetadataPluginEngine>(mockEngine);
    sl.registerLazySingleton<NoticeBus>(() => NoticeBus());
  });

  tearDown(() {
    sl.reset();
  });

  Widget buildTestWidget({
    double textScale = 1.0,
    MetadataPluginCubit? metadataCubit,
  }) {
    return BlocProvider<MetadataPluginCubit>.value(
      value: metadataCubit ?? buildMockMetadataPluginCubit(),
      child: BlocProvider<PlayerCubit>.value(
        value: mockPlayerCubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: NoticeListener(
            notices: sl<NoticeBus>().notices,
            child: const SearchPage(),
          ),
        ),
      ),
    );
  }

  List<Album> buildAlbums(int count) => List.generate(
    count,
    (i) => Album(
      id: 'al$i',
      name: 'Album Number $i With A Fairly Long Name',
      artists: const [],
      releaseDate: '2023',
      externalUri: '',
      totalTracks: 10,
      albumType: AlbumType.album,
    ),
  );

  testWidgets('SearchPage shows empty prompt initially and renders chips', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Search Music'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
  });

  group('typed chip subsets', () {
    Future<void> pumpWithChips(
      WidgetTester tester,
      List<SearchCategory> chips,
    ) async {
      when(() => mockSearch.chips()).thenAnswer((_) async => chips);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
    }

    testWidgets('an empty subset leaves only the aggregate chip', (
      tester,
    ) async {
      await pumpWithChips(tester, const []);

      expect(find.byType(FilterChip), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a one-category subset renders host-side localized labels', (
      tester,
    ) async {
      await pumpWithChips(tester, const [SearchCategory.albums]);

      expect(find.byType(FilterChip), findsNWidgets(2));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Songs'), findsNothing);
    });

    testWidgets('all four categories render their localized labels', (
      tester,
    ) async {
      await pumpWithChips(tester, SearchCategory.values);

      for (final label in ['All', 'Songs', 'Albums', 'Artists', 'Playlists']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('every declared category loads by value and never renders '
        'an empty body', (tester) async {
      when(
        () => mockSearch.chips(),
      ).thenAnswer((_) async => SearchCategory.values);
      when(
        () => mockSearch.tracks(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [dummyTrack],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );
      when(
        () => mockSearch.albums(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Album>(
          items: buildAlbums(3),
          total: 3,
          offset: 0,
          limit: 20,
        ),
      );
      when(
        () => mockSearch.artists(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Artist>(
          items: [dummyArtist],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );
      when(
        () => mockSearch.playlists(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Playlist>(
          items: [dummyPlaylist],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Coldplay');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final cubit = BlocProvider.of<SearchCubit>(
        tester.element(find.byType(FilterChip).first),
      );

      for (final category in SearchCategory.values) {
        await cubit.selectChip(category);
        await tester.pumpAndSettle();

        expect(cubit.state.selectedChip, category);
        if (category == SearchCategory.tracks) {
          expect(
            find.byType(TrackListTile),
            findsWidgets,
            reason: 'tracks must render its list, not an empty body',
          );
        } else {
          expect(
            find.byType(MediaCard),
            findsWidgets,
            reason: '$category must render its grid, not an empty body',
          );
        }
        expect(tester.takeException(), isNull);
      }

      verify(
        () => mockSearch.tracks(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).called(1);
      verify(
        () => mockSearch.albums(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).called(1);
      verify(
        () => mockSearch.artists(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).called(1);
      verify(
        () => mockSearch.playlists(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).called(1);

      await cubit.selectChip(null);
      await tester.pumpAndSettle();

      expect(cubit.state.isAllCategory, isTrue);
      expect(find.byType(MediaCard), findsWidgets);
    });
  });

  testWidgets('SearchPage triggers search on typing and displays results', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.enterText(textField, 'Coldplay');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    verify(() => mockSearch.all('Coldplay')).called(1);
    expect(find.text('Yellow'), findsOneWidget);
    expect(find.text('Parachutes'), findsOneWidget);
    expect(find.text('Coldplay'), findsWidgets);
  });

  testWidgets(
    'SearchPage renders the Playlists carousel in the aggregated view',
    (tester) async {
      when(() => mockSearch.all(any())).thenAnswer(
        (_) async => SearchResponse(
          tracks: [],
          albums: [],
          artists: [],
          playlists: [dummyPlaylist],
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Coldplay');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final section = find.widgetWithText(SectionRow, 'Playlists');
      expect(section, findsOneWidget);
      expect(
        find.descendant(of: section, matching: find.byType(MediaCard)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SearchPage category filter switches to category view and plays track',
    (tester) async {
      when(
        () => mockSearch.tracks(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [dummyTrack],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Coldplay');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final songsChip = find.widgetWithText(FilterChip, 'Songs');
      await tester.tap(songsChip);
      await tester.pumpAndSettle();

      verify(
        () => mockSearch.tracks('Coldplay', offset: 0, limit: 20),
      ).called(1);

      // Tap track tile to play
      final trackTile = find.byType(TrackListTile);
      expect(trackTile, findsOneWidget);

      when(
        () => mockPlayerCubit.playQueue(any(), index: any(named: 'index')),
      ).thenAnswer((_) async {});

      await tester.tap(trackTile);
      await tester.pump();

      verify(() => mockPlayerCubit.playQueue([dummyTrack], index: 0)).called(1);
    },
  );

  testWidgets(
    'SearchPage displays SkeletonSearchAll during initial loading for All category',
    (tester) async {
      final completer = Completer<SearchResponse>();
      when(() => mockSearch.all(any())).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Coldplay');
      // Advance past debounce timer (350ms)
      await tester.pump(const Duration(milliseconds: 360));

      expect(find.byType(SkeletonSearchAll), findsOneWidget);

      // Complete future to clean up pending timers
      completer.complete(dummyResponse);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'SearchPage displays SkeletonTrackList and SkeletonMediaGrid during category loading',
    (tester) async {
      final tracksCompleter = Completer<PaginatedResult<Track>>();
      final albumsCompleter = Completer<PaginatedResult<Album>>();

      when(
        () => mockSearch.tracks(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => tracksCompleter.future);

      when(
        () => mockSearch.albums(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => albumsCompleter.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Coldplay');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final songsChip = find.widgetWithText(FilterChip, 'Songs');
      await tester.tap(songsChip);
      await tester.pump(); // Start request

      expect(find.byType(SkeletonTrackList), findsOneWidget);

      tracksCompleter.complete(
        PaginatedResult<Track>(
          items: [dummyTrack],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );
      await tester.pumpAndSettle();

      final albumsChip = find.widgetWithText(FilterChip, 'Albums');
      await tester.tap(albumsChip);
      await tester.pump(); // Start request

      expect(find.byType(SkeletonMediaGrid), findsOneWidget);

      albumsCompleter.complete(
        PaginatedResult<Album>(items: [], total: 0, offset: 0, limit: 20),
      );
      await tester.pumpAndSettle();
    },
  );

  group('Albums grid overflow regression', () {
    final viewports = <Size>[
      const Size(320, 640),
      const Size(360, 800),
      const Size(411, 891),
      const Size(800, 600),
    ];

    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final viewport in viewports) {
        testWidgets('renders Albums grid without overflow (scale $scale, '
            '${viewport.width.toInt()}x${viewport.height.toInt()})', (
          tester,
        ) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          when(
            () => mockSearch.albums(
              'Coldplay',
              offset: 0,
              limit: any(named: 'limit'),
            ),
          ).thenAnswer(
            (_) async => PaginatedResult<Album>(
              items: buildAlbums(6),
              total: 6,
              offset: 0,
              limit: 20,
            ),
          );

          await tester.pumpWidget(buildTestWidget(textScale: scale));
          await tester.pumpAndSettle();

          await tester.enterText(find.byType(TextField), 'Coldplay');
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pumpAndSettle();

          // Select via the cubit: the chip can be off-screen at narrow
          // widths / large text scales, so tapping it is unreliable.
          final cubit = BlocProvider.of<SearchCubit>(
            tester.element(find.byType(FilterChip).first),
          );
          cubit.selectChip(SearchCategory.albums);
          await tester.pumpAndSettle();

          verify(
            () => mockSearch.albums(
              'Coldplay',
              offset: 0,
              limit: any(named: 'limit'),
            ),
          ).called(1);
          expect(find.byType(MediaCard), findsWidgets);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('skeleton grid cell matches real MediaCard cell', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 1. Measure the skeleton cell.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonMediaGrid(itemCount: 4)),
        ),
      );
      final skeletonSize = tester.getSize(find.byType(ShimmerBox).first);

      // 2. Measure a real MediaCard inside the search grid.
      when(
        () => mockSearch.albums(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Album>(
          items: buildAlbums(6),
          total: 6,
          offset: 0,
          limit: 20,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Coldplay');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      BlocProvider.of<SearchCubit>(
        tester.element(find.byType(FilterChip).first),
      ).selectChip(SearchCategory.albums);
      await tester.pumpAndSettle();

      final realSize = tester.getSize(find.byType(MediaCard).first);

      expect(realSize.width, closeTo(skeletonSize.width, 0.01));
      expect(realSize.height, closeTo(skeletonSize.height, 0.01));
    });
  });

  testWidgets(
    'selected FilterChip uses the primary color with onPrimary label',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final selectedChip = tester.widget<FilterChip>(
        find.byWidgetPredicate(
          (widget) => widget is FilterChip && widget.selected,
        ),
      );

      final colorScheme = Theme.of(
        tester.element(find.byType(SearchPage)),
      ).colorScheme;
      expect(selectedChip.selectedColor, colorScheme.primary);
      expect(selectedChip.labelStyle?.color, colorScheme.onPrimary);
    },
  );

  testWidgets(
    'progressive loading shows a full row of grid skeletons, not a spinner',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final loadMoreCompleter = Completer<PaginatedResult<Album>>();

      when(
        () => mockSearch.albums(
          'Coldplay',
          offset: 0,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Album>(
          items: buildAlbums(4),
          total: 8,
          offset: 0,
          limit: 4,
        ),
      );
      when(
        () => mockSearch.albums(
          'Coldplay',
          offset: 4,
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => loadMoreCompleter.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Coldplay');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final cubit = BlocProvider.of<SearchCubit>(
        tester.element(find.byType(FilterChip).first),
      );
      await cubit.selectChip(SearchCategory.albums);
      await tester.pumpAndSettle();
      expect(cubit.state.hasMore, isTrue);

      // Trigger the next page directly: a scroll gesture is unreliable here.
      unawaited(cubit.loadMore());
      await tester.pump();
      await tester.pump();

      expect(cubit.state.isLoadingMore, isTrue);
      expect(find.byType(MediaCard), findsNWidgets(4));
      final columns = MediaCardMetrics.gridColumns(800);
      expect(find.byType(ShimmerBox), findsNWidgets(columns));
      expect(find.byType(CircularProgressIndicator), findsNothing);

      loadMoreCompleter.complete(
        PaginatedResult<Album>(
          items: buildAlbums(4),
          total: 8,
          offset: 4,
          limit: 4,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerBox), findsNothing);
    },
  );

  testWidgets('a failed load-more keeps the results and shows no error card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    when(
      () => mockSearch.albums(
        'Coldplay',
        offset: 0,
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResult<Album>(
        items: buildAlbums(4),
        total: 8,
        offset: 0,
        limit: 4,
      ),
    );
    when(
      () => mockSearch.albums(
        'Coldplay',
        offset: 4,
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => throw Exception('boom'));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Coldplay');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final cubit = BlocProvider.of<SearchCubit>(
      tester.element(find.byType(FilterChip).first),
    );
    await cubit.selectChip(SearchCategory.albums);
    await tester.pumpAndSettle();
    expect(cubit.state.hasMore, isTrue);

    await cubit.loadMore();
    await tester.pumpAndSettle();

    expect(cubit.state.loadMoreError, isNotNull);
    expect(cubit.state.error, isNull);
    expect(find.byType(MediaCard), findsNWidgets(4));
    expect(find.byType(ErrorCard), findsNothing);
  });

  group('non-list states scroll in landscape without overflow', () {
    const viewports = <Size>[Size(800, 360), Size(800, 320), Size(800, 280)];

    void useViewport(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    for (final viewport in viewports) {
      final label = '${viewport.width.toInt()}x${viewport.height.toInt()}';

      testWidgets('empty state has no overflow at $label', (tester) async {
        useViewport(tester, viewport);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(InfoCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('error state has no overflow at $label', (tester) async {
        useViewport(tester, viewport);
        when(() => mockSearch.all(any())).thenThrow(Exception('Search failed'));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Coldplay');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.byType(ErrorCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('no results state has no overflow at $label', (tester) async {
        useViewport(tester, viewport);
        when(() => mockSearch.all(any())).thenAnswer(
          (_) async => SearchResponse(
            tracks: const [],
            albums: const [],
            artists: const [],
            playlists: const [],
          ),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Coldplay');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.byType(InfoCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('account entry point and auth refresh', () {
    testWidgets('keeps the title, the settings button and the pinned field', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Search'), findsOneWidget);
      expect(find.byType(SettingsButton), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('focuses the search field when the branch is visible', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isTrue);
    });

    testWidgets('keeps the keyboard closed while the branch is offstage', (
      tester,
    ) async {
      await tester.pumpWidget(
        TickerMode(enabled: false, child: buildTestWidget()),
      );
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('announces an auth-required search failure', (tester) async {
      when(() => mockSearch.all(any())).thenAnswer(
        (_) async => throw const MetadataAuthRequiredException('sign in'),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Coldplay');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Metadata sign-in required.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('focuses the field again when the branch becomes visible', (
      tester,
    ) async {
      await tester.pumpWidget(
        TickerMode(enabled: false, child: buildTestWidget()),
      );
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.pumpWidget(
        TickerMode(enabled: true, child: buildTestWidget()),
      );
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
    });
  });
}
