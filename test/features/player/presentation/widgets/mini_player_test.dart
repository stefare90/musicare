import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
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
    });

    Widget buildTestableWidget({VoidCallback? onExpand}) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<PlayerCubit>.value(
            value: mockPlayerCubit,
            child: MiniPlayer(onExpand: onExpand),
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

    testWidgets('renders track title, artist, and pause icon when playing', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          status: PlayerStatus.playing,
          currentTrack: testTrack,
          queue: [testTrack],
          currentIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('The Beatles'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });

    testWidgets('tapping play/pause button triggers cubit togglePlayPause', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          status: PlayerStatus.playing,
          currentTrack: testTrack,
          queue: [testTrack],
          currentIndex: 0,
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
          status: PlayerStatus.playing,
          currentTrack: testTrack,
          queue: [testTrack, track2],
          currentIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pumpAndSettle();

      verify(() => mockPlayerCubit.next()).called(1);
    });

    testWidgets('tapping body triggers onExpand callback', (tester) async {
      var didExpand = false;
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          status: PlayerStatus.playing,
          currentTrack: testTrack,
          queue: [testTrack],
          currentIndex: 0,
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(onExpand: () => didExpand = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Come Together'));
      await tester.pumpAndSettle();

      expect(didExpand, isTrue);
    });
  });
}
