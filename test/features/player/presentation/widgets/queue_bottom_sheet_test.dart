import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/bottom_sheets/queue_bottom_sheet.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/cubit/queue_state.dart';

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
  group('QueueBottomSheet Widget Tests', () {
    late MockPlayerCubit mockPlayerCubit;
    final track1 = createTestTrack('t1', 'Come Together');
    final track2 = createTestTrack('t2', 'Something');

    setUp(() {
      mockPlayerCubit = MockPlayerCubit();
      when(() => mockPlayerCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockPlayerCubit.skipToIndex(any())).thenAnswer((_) async {});
      when(() => mockPlayerCubit.removeFromQueue(any())).thenReturn(null);
      when(() => mockPlayerCubit.reorderQueue(any(), any())).thenReturn(null);
    });

    Widget buildTestableWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<PlayerCubit>.value(
            value: mockPlayerCubit,
            child: const QueueBottomSheet(),
          ),
        ),
      );
    }

    testWidgets('renders empty message when queue is empty', (tester) async {
      when(() => mockPlayerCubit.state).thenReturn(const PlayerState());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Playback Queue'), findsOneWidget);
      expect(find.text('Queue is empty'), findsOneWidget);
    });

    testWidgets('renders list of tracks in queue and highlights current track', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          queue: QueueState(
            tracks: [track1, track2],
            currentIndex: 0,
            hasNext: true,
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Playback Queue'), findsOneWidget);
      expect(find.text('(2)'), findsOneWidget);
      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('Something'), findsOneWidget);
      expect(find.byIcon(Icons.equalizer_rounded), findsOneWidget);
    });

    testWidgets('tapping track skips to index', (tester) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(
          queue: QueueState(
            tracks: [track1, track2],
            currentIndex: 0,
            hasNext: true,
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Something'));
      await tester.pumpAndSettle();

      verify(() => mockPlayerCubit.skipToIndex(1)).called(1);
    });
  });
}
