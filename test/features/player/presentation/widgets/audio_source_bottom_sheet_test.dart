import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/bottom_sheets/audio_source_bottom_sheet.dart';
import 'package:music_are/features/player/presentation/cubit/candidates_state.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

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
  group('AudioSourceBottomSheet Widget Tests', () {
    late MockPlayerCubit mockPlayerCubit;
    final track = createTestTrack('t1', 'Come Together');

    const candidate1 = CandidateTrack(
      id: 'c1',
      title: 'Come Together (Official Video)',
      artist: 'The Beatles Official',
      durationMs: 259000,
    );

    const candidate2 = CandidateTrack(
      id: 'c2',
      title: 'Come Together (Live at Wembley)',
      artist: 'Live Music Archive',
      durationMs: 270000,
    );

    setUp(() {
      mockPlayerCubit = MockPlayerCubit();
      when(() => mockPlayerCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockPlayerCubit.selectStreamCandidate(any())).thenAnswer((_) async {});
    });

    Widget buildTestableWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<PlayerCubit>.value(
            value: mockPlayerCubit,
            child: AudioSourceBottomSheet(track: track),
          ),
        ),
      );
    }

    testWidgets('renders candidates list with real titles, artists, and active badge', (tester) async {
      when(() => mockPlayerCubit.state).thenReturn(
        const PlayerState(
          candidates: CandidatesState(
            candidates: [candidate1, candidate2],
            activeCandidateId: 'c1',
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Audio Stream Candidates'), findsOneWidget);
      expect(find.text('2 available stream(s)'), findsOneWidget);
      expect(find.text('Come Together (Official Video)'), findsOneWidget);
      expect(find.text('The Beatles Official • 04:19'), findsOneWidget);
      expect(find.text('Come Together (Live at Wembley)'), findsOneWidget);
      expect(find.text('Live Music Archive • 04:30'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('tapping candidate selects stream candidate on cubit', (tester) async {
      when(() => mockPlayerCubit.state).thenReturn(
        const PlayerState(
          candidates: CandidatesState(
            candidates: [candidate1, candidate2],
            activeCandidateId: 'c1',
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Come Together (Live at Wembley)'));
      await tester.pumpAndSettle();

      verify(() => mockPlayerCubit.selectStreamCandidate(1)).called(1);
    });
  });
}
