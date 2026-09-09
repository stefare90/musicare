import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/cubit/queue_state.dart';
import 'package:music_are/features/player/presentation/widgets/mini_player.dart';

class MockPlayerCubit extends Mock implements PlayerCubit {}

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
  group('MiniPlayer Widget Tests', () {
    late MockPlayerCubit mockPlayerCubit;
    final testTrack = createTestTrack('t1', 'Come Together');

    setUp(() {
      mockPlayerCubit = MockPlayerCubit();
      when(
        () => mockPlayerCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockPlayerCubit.togglePlayPause()).thenAnswer((_) async {});
      when(() => mockPlayerCubit.next()).thenAnswer((_) async {});
      when(() => mockPlayerCubit.previous()).thenAnswer((_) async {});
    });

    Widget buildTestableWidget({VoidCallback? onTap}) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<PlayerCubit>.value(
            value: mockPlayerCubit,
            child: MiniPlayer(onTap: onTap),
          ),
        ),
      );
    }

    testWidgets('renders empty space when currentTrack is null', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(const PlayerState());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Come Together'), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('renders track title, artist, and playback icons', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          isPlaying: true,
          processingState: PlaybackProcessingState.ready,
          queue: QueueState(
            tracks: [testTrack, createTestTrack('t2', 'Track 2')],
            currentIndex: 1,
            hasNext: true,
            hasPrevious: true,
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Track 2'), findsOneWidget);
      expect(find.text('The Beatles'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);

      final previousButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.skip_previous_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(previousButton.onPressed, isNotNull);
    });

    testWidgets('disables previous button when hasPrevious is false', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          isPlaying: true,
          processingState: PlaybackProcessingState.ready,
          queue: QueueState(
            tracks: [testTrack],
            currentIndex: 0,
            hasNext: false,
            hasPrevious: false,
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final previousButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.skip_previous_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(previousButton.onPressed, isNull);
    });

    testWidgets('shows loading spinner when processingState is loading', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          processingState: PlaybackProcessingState.loading,
          queue: QueueState(tracks: [testTrack]),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('tapping play/pause button triggers cubit togglePlayPause', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          isPlaying: true,
          processingState: PlaybackProcessingState.ready,
          queue: QueueState(tracks: [testTrack]),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();

      verify(() => mockPlayerCubit.togglePlayPause()).called(1);
    });

    testWidgets('tapping skip next triggers cubit next when hasNext is true', (
      tester,
    ) async {
      final track2 = createTestTrack('t2', 'Something');
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          isPlaying: true,
          processingState: PlaybackProcessingState.ready,
          queue: QueueState(
            tracks: [testTrack, track2],
            currentIndex: 0,
            hasNext: true,
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pumpAndSettle();

      verify(() => mockPlayerCubit.next()).called(1);
    });

    testWidgets(
      'tapping skip previous triggers cubit previous when hasPrevious is true',
      (tester) async {
        final track2 = createTestTrack('t2', 'Something');
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(
            isPlaying: true,
            processingState: PlaybackProcessingState.ready,
            queue: QueueState(
              tracks: [testTrack, track2],
              currentIndex: 1,
              hasNext: false,
              hasPrevious: true,
            ),
          ),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.skip_previous_rounded));
        await tester.pumpAndSettle();

        verify(() => mockPlayerCubit.previous()).called(1);
      },
    );

    testWidgets('tapping body triggers onTap callback', (tester) async {
      bool wasTapped = false;
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          isPlaying: true,
          processingState: PlaybackProcessingState.ready,
          queue: QueueState(tracks: [testTrack]),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(onTap: () => wasTapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Come Together'));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });
  });
}
