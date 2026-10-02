import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../helpers/metadata_plugin_test_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/bottom_sheets/audio_source_bottom_sheet.dart';
import 'package:music_are/core/widgets/bottom_sheets/queue_bottom_sheet.dart';
import 'package:music_are/features/player/data/models/playback_repeat_mode.dart';
import 'package:music_are/features/player/presentation/cubit/candidates_state.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/cubit/queue_state.dart';
import 'package:music_are/features/player/presentation/pages/full_player_page.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_cubit.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

class MockPlayerCubit extends Mock implements PlayerCubit {}

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

Track createTestTrack(String id, String name) {
  return Track(
    id: id,
    name: name,
    externalUri: '',
    artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
    album: Album(
      id: 'al1',
      name: 'Abbey Road',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 1,
      albumType: AlbumType.album,
    ),
    durationMs: 200000,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  group('FullPlayerPage Widget Tests', () {
    late MockPlayerCubit mockPlayerCubit;
    final testTrack = createTestTrack('t1', 'Come Together');
    const testCandidate = AudioStreamResponse(
      url: 'https://cdn.example.com/audio.m4a',
      quality: AudioQuality.high,
      codec: 'm4a',
      bitrate: 160000,
    );
    const candidateTrack = CandidateTrack(
      id: 'c1',
      title: 'Come Together',
      artist: 'The Beatles',
    );

    setUp(() {
      mockPlayerCubit = MockPlayerCubit();
      when(
        () => mockPlayerCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockPlayerCubit.togglePlayPause()).thenAnswer((_) async {});
      when(() => mockPlayerCubit.next()).thenAnswer((_) async {});
      when(() => mockPlayerCubit.previous()).thenAnswer((_) async {});
      when(() => mockPlayerCubit.toggleShuffle()).thenReturn(null);
      when(() => mockPlayerCubit.cycleRepeatMode()).thenReturn(null);
      when(() => mockPlayerCubit.seek(any())).thenAnswer((_) async {});
      when(
        () => mockPlayerCubit.selectStreamCandidate(any()),
      ).thenAnswer((_) async {});
    });

    Widget buildTestableWidget({
      VoidCallback? onCollapse,
      Size size = const Size(400, 800),
    }) {
      final engine = MockPluginEngine();
      when(() => engine.hasMetadata).thenReturn(false);
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<PlayerCubit>.value(value: mockPlayerCubit),
                BlocProvider<SavedMediaCubit>(
                  create: (_) => SavedMediaCubit(
                    LibraryRepository(engine),
                    NoticeBus(),
                    auth: TestAccountCubit(testAccountState()),
                  ),
                ),
              ],
              child: FullPlayerPage(onCollapse: onCollapse),
            ),
          ),
        ),
      );
    }

    testWidgets('renders empty view when track is null', (tester) async {
      when(() => mockPlayerCubit.state).thenReturn(const PlayerState());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.text('Come Together'), findsNothing);
    });

    testWidgets(
      'renders portrait layout with track metadata, playback buttons, and utilities',
      (tester) async {
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(
            isPlaying: true,
            position: const Duration(seconds: 45),
            duration: const Duration(seconds: 200),
            candidates: const CandidatesState(
              candidates: [candidateTrack],
              activeStream: testCandidate,
              activeCandidateId: 'c1',
            ),
            queue: QueueState(
              tracks: [testTrack, createTestTrack('t2', 'Track 2')],
              currentIndex: 0,
              hasNext: true,
              hasPrevious: false,
              isShuffled: true,
              repeatMode: PlaybackRepeatMode.all,
            ),
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(size: const Size(400, 800)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Come Together'), findsOneWidget);
        expect(find.text('The Beatles'), findsOneWidget);
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
        expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
        expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
        expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
        expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
        expect(find.byIcon(Icons.lyrics_outlined), findsOneWidget);
        expect(find.byIcon(Icons.download_rounded), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
        expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
      },
    );

    testWidgets('renders landscape two-column layout when width > height', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          isPlaying: true,
          position: const Duration(seconds: 45),
          duration: const Duration(seconds: 200),
          candidates: const CandidatesState(
            candidates: [candidateTrack],
            activeStream: testCandidate,
            activeCandidateId: 'c1',
          ),
          queue: QueueState(
            tracks: [testTrack],
            currentIndex: 0,
            isShuffled: false,
            repeatMode: PlaybackRepeatMode.off,
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget(size: const Size(800, 400)));
      await tester.pumpAndSettle();

      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('The Beatles'), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('tapping play/pause calls togglePlayPause', (tester) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(isPlaying: true, queue: QueueState(tracks: [testTrack])),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();

      verify(() => mockPlayerCubit.togglePlayPause()).called(1);
    });

    testWidgets('tapping audio source icon opens AudioSourceBottomSheet', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          queue: QueueState(tracks: [testTrack]),
          candidates: const CandidatesState(
            candidates: [candidateTrack],
            activeStream: testCandidate,
            activeCandidateId: 'c1',
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.graphic_eq_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AudioSourceBottomSheet), findsOneWidget);
    });

    testWidgets('tapping queue icon opens QueueBottomSheet', (tester) async {
      when(
        () => mockPlayerCubit.state,
      ).thenReturn(PlayerState(queue: QueueState(tracks: [testTrack])));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.queue_music_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(QueueBottomSheet), findsOneWidget);
    });
  });
}
