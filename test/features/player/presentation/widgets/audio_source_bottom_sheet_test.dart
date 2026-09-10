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

    const stream1 = AudioStreamResponse(
      url: 'https://rr1.googlevideo.com/audio1.m4a',
      quality: AudioQuality.high,
      codec: 'm4a',
      bitrate: 160000,
    );

    const stream2 = AudioStreamResponse(
      url: 'https://rr2.googlevideo.com/audio2.opus',
      quality: AudioQuality.medium,
      codec: 'opus',
      bitrate: 128000,
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

    testWidgets('renders candidates list and active badge', (tester) async {
      when(() => mockPlayerCubit.state).thenReturn(
        const PlayerState(
          candidates: CandidatesState(
            streams: [stream1, stream2],
            activeIndex: 0,
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Audio Stream Candidates'), findsOneWidget);
      expect(find.text('2 available stream(s)'), findsOneWidget);
      expect(find.text('Candidate #1 (M4A • 160 kbps)'), findsOneWidget);
      expect(find.text('Candidate #2 (OPUS • 128 kbps)'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('tapping candidate selects stream candidate on cubit', (tester) async {
      when(() => mockPlayerCubit.state).thenReturn(
        const PlayerState(
          candidates: CandidatesState(
            streams: [stream1, stream2],
            activeIndex: 0,
          ),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Candidate #2 (OPUS • 128 kbps)'));
      await tester.pumpAndSettle();

      verify(() => mockPlayerCubit.selectStreamCandidate(1)).called(1);
    });
  });
}
