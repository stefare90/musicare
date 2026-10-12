import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/models/pending_source.dart';
import 'package:music_are/features/player/data/models/playback_candidates.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/services/audio_player_driver.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

class MockAudioPlayerDriver extends Mock implements AudioPlayerDriver {}

class MockAudioStreamResolver extends Mock implements AudioStreamResolver {}

Track createPendingTestTrack(String id, String name) {
  return Track(
    id: id,
    name: name,
    externalUri: '',
    artists: [Artist(id: 'a1', name: 'Artist', externalUri: '')],
    album: Album(
      id: 'al1',
      name: 'Album',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 10,
      albumType: AlbumType.album,
    ),
    durationMs: 180000,
  );
}

List<Track> makeTracks(int count, [String prefix = 't']) =>
    List.generate(count, (i) => createPendingTestTrack('$prefix$i', 'Song $i'));

PaginatedResult<Track> pageOf(
  List<Track> all,
  int offset, {
  int limit = 20,
}) {
  return PaginatedResult<Track>(
    items: all.skip(offset).take(limit).toList(),
    total: all.length,
    offset: offset,
    limit: limit,
  );
}

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(createPendingTestTrack('fb_id', 'fb_name'));
    registerFallbackValue(
      const AudioStreamResponse(
        url: 'https://fallback.example.com',
        quality: AudioQuality.high,
      ),
    );
    registerFallbackValue(Duration.zero);
    registerFallbackValue(AudioQuality.high);
  });

  group('AudioPlayerService pending source (S1)', () {
    late MockAudioPlayerDriver mockDriver;
    late MockAudioStreamResolver mockResolver;
    late AudioPlayerService service;

    late StreamController<PlaybackProcessingState> processingController;
    late StreamController<bool> playingController;
    late StreamController<Duration> positionController;
    late StreamController<Duration?> durationController;

    const candidate = CandidateTrack(id: 'c1', title: 'Song (Official)');
    const stream = AudioStreamResponse(
      url: 'https://cdn.example.com/audio.m4a',
      quality: AudioQuality.high,
    );

    setUp(() {
      mockDriver = MockAudioPlayerDriver();
      mockResolver = MockAudioStreamResolver();

      processingController =
          StreamController<PlaybackProcessingState>.broadcast();
      playingController = StreamController<bool>.broadcast();
      positionController = StreamController<Duration>.broadcast();
      durationController = StreamController<Duration?>.broadcast();

      when(
        () => mockDriver.processingStateStream,
      ).thenAnswer((_) => processingController.stream);
      when(
        () => mockDriver.isPlayingStream,
      ).thenAnswer((_) => playingController.stream);
      when(
        () => mockDriver.positionStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        () => mockDriver.durationStream,
      ).thenAnswer((_) => durationController.stream);

      when(() => mockDriver.isPlaying).thenReturn(false);
      when(() => mockDriver.position).thenReturn(Duration.zero);
      when(() => mockDriver.duration).thenReturn(Duration.zero);
      when(
        () => mockDriver.processingState,
      ).thenReturn(PlaybackProcessingState.idle);

      when(
        () => mockDriver.loadStream(
          track: any(named: 'track'),
          stream: any(named: 'stream'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockDriver.play()).thenAnswer((_) async {});
      when(() => mockDriver.pause()).thenAnswer((_) async {});
      when(() => mockDriver.stop()).thenAnswer((_) async {});
      when(() => mockDriver.seek(any())).thenAnswer((_) async {});
      when(() => mockDriver.dispose()).thenAnswer((_) async {});

      when(() => mockResolver.resolveTrack(any())).thenAnswer(
        (_) async => const PlaybackCandidates(
          candidates: [candidate],
          activeStream: stream,
          activeCandidateId: 'c1',
        ),
      );

      service = AudioPlayerService(driver: mockDriver, resolver: mockResolver);
    });

    tearDown(() async {
      await processingController.close();
      await playingController.close();
      await positionController.close();
      await durationController.close();
      await service.dispose();
    });

    test('fills the whole list after playQueue', () async {
      final all = makeTracks(25);
      final offsets = <int>[];
      Future<PaginatedResult<Track>> loader(int offset) async {
        offsets.add(offset);
        return pageOf(all, offset);
      }

      await service.playQueue(
        all.take(5).toList(),
        index: 0,
        pending: PendingSource(
          loader: loader,
          nextOffset: 5,
          total: 25,
        ),
      );
      await settle();

      expect(offsets, equals([5]));
      expect(service.playbackData.queue.length, equals(25));
      expect(service.playbackData.pending.isEmpty, isTrue);
    });

    test('fill walks through multiple pages until complete', () async {
      final all = makeTracks(15);
      final offsets = <int>[];
      Future<PaginatedResult<Track>> loader(int offset) async {
        offsets.add(offset);
        return pageOf(all, offset, limit: 5);
      }

      await service.playQueue(
        all.take(5).toList(),
        index: 0,
        pending: PendingSource(
          loader: loader,
          nextOffset: 5,
          total: 15,
        ),
      );
      await settle();

      expect(offsets, equals([5, 10]));
      expect(service.playbackData.queue.length, equals(15));
      expect(service.playbackData.pending.isEmpty, isTrue);
    });

    test('empty page completes the pending without touching the queue',
        () async {
      Future<PaginatedResult<Track>> loader(int offset) async {
        return PaginatedResult<Track>(
          items: const [],
          total: 5,
          offset: offset,
          limit: 20,
        );
      }

      final first = makeTracks(5);
      await service.playQueue(
        first,
        index: 4,
        pending: PendingSource(
          loader: loader,
          nextOffset: 5,
          total: 99,
        ),
      );
      await settle();

      expect(service.playbackData.queue.length, equals(5));
      expect(service.playbackData.pending.isEmpty, isTrue);
      expect(service.playbackData.pending.error, isNull);
    });

    test(
      'recovers from a transient failure inside the burst',
      () async {
        final all = makeTracks(10);
        var calls = 0;
        Future<PaginatedResult<Track>> loader(int offset) async {
          calls++;
          if (calls == 1) throw Exception('network down');
          return pageOf(all, offset, limit: 5);
        }

        await service.playQueue(
          all.take(5).toList(),
          index: 4,
          pending: PendingSource(
            loader: loader,
            nextOffset: 5,
            total: 10,
          ),
        );
        await settle();

        expect(calls, equals(2));
        expect(service.playbackData.queue.length, equals(10));
        expect(service.playbackData.pending.error, isNull);
      },
    );

    test(
      'persistent failure stops after four attempts; only manual retry resumes',
      () async {
        final all = makeTracks(10);
        var calls = 0;
        var fail = true;
        Future<PaginatedResult<Track>> loader(int offset) async {
          calls++;
          if (fail) throw Exception('network down');
          return pageOf(all, offset, limit: 5);
        }

        await service.playQueue(
          all.take(5).toList(),
          index: 0,
          pending: PendingSource(
            loader: loader,
            nextOffset: 5,
            total: 10,
          ),
        );
        await settle();

        expect(calls, equals(4));
        expect(service.playbackData.queue.length, equals(5));
        expect(service.playbackData.pending.error, isA<PendingLoadException>());
        expect(service.playbackData.pending.nextOffset, equals(5));

        await service.skipToIndex(4);
        await settle();
        expect(calls, equals(4));

        fail = false;
        await service.retryPendingLoad();
        await settle();
        expect(calls, equals(5));
        expect(service.playbackData.queue.length, equals(10));
        expect(service.playbackData.pending.error, isNull);
      },
    );

    test('next() at the end does not retry a recorded error', () async {
      final all = makeTracks(25);
      var calls = 0;
      Future<PaginatedResult<Track>> loader(int offset) async {
        calls++;
        throw Exception('network down');
      }

      await service.playQueue(
        all.take(5).toList(),
        index: 4,
        pending: PendingSource(
          loader: loader,
          nextOffset: 5,
          total: 25,
        ),
      );
      await settle();
      expect(calls, equals(4));
      expect(service.playbackData.pending.error, isNotNull);

      await service.next();

      expect(calls, equals(4));
      verify(() => mockDriver.stop()).called(1);
      expect(service.playbackData.currentTrack?.id, equals('t4'));
    });

    test('retryPendingLoad resumes the full fill after exhaustion', () async {
      final all = makeTracks(10);
      var calls = 0;
      var fail = true;
      Future<PaginatedResult<Track>> loader(int offset) async {
        calls++;
        if (fail) throw Exception('network down');
        return pageOf(all, offset, limit: 5);
      }

      await service.playQueue(
        all.take(5).toList(),
        index: 4,
        pending: PendingSource(
          loader: loader,
          nextOffset: 5,
          total: 10,
        ),
      );
      await settle();
      expect(calls, equals(4));
      expect(service.playbackData.pending.error, isNotNull);

      fail = false;
      await service.retryPendingLoad();
      await settle();

      expect(calls, equals(5));
      expect(service.playbackData.queue.length, equals(10));
      expect(service.playbackData.pending.error, isNull);
    });

    test('retap during a slow flight adopts the new pending', () async {
      final a = makeTracks(25, 'a');
      final b = makeTracks(25, 'b');
      final gateA = Completer<PaginatedResult<Track>>();
      var callsA = 0;
      Future<PaginatedResult<Track>> slowA(int offset) async {
        callsA++;
        return gateA.future;
      }
      final callsB = <int>[];
      Future<PaginatedResult<Track>> fastB(int offset) async {
        callsB.add(offset);
        return pageOf(b, offset);
      }

      await service.playQueue(
        a.take(5).toList(),
        index: 0,
        pending: PendingSource(
          loader: slowA,
          nextOffset: 5,
          total: 25,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await service.playQueue(
        b.take(5).toList(),
        index: 0,
        pending: PendingSource(
          loader: fastB,
          nextOffset: 5,
          total: 25,
        ),
      );
      gateA.complete(pageOf(a, 5));
      await settle();

      expect(callsA, equals(1));
      expect(callsB, equals([5]));
      expect(
        service.playbackData.queue.tracks.map((t) => t.id),
        equals(b.map((t) => t.id)),
      );
      expect(service.playbackData.pending.isEmpty, isTrue);
    });

    test('retap during a failing flight adopts the new pending', () async {
      final a = makeTracks(25, 'a');
      final b = makeTracks(25, 'b');
      final gateA = Completer<PaginatedResult<Track>>();
      Future<PaginatedResult<Track>> slowA(int offset) => gateA.future;
      final callsB = <int>[];
      Future<PaginatedResult<Track>> fastB(int offset) async {
        callsB.add(offset);
        return pageOf(b, offset);
      }

      await service.playQueue(
        a.take(5).toList(),
        index: 0,
        pending: PendingSource(
          loader: slowA,
          nextOffset: 5,
          total: 25,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await service.playQueue(
        b.take(5).toList(),
        index: 0,
        pending: PendingSource(
          loader: fastB,
          nextOffset: 5,
          total: 25,
        ),
      );
      gateA.completeError(Exception('gone'));
      await settle();

      expect(callsB, equals([5]));
      expect(service.playbackData.queue.length, equals(25));
      expect(service.playbackData.pending.error, isNull);
    });

    test('second playQueue supersedes the first pending', () async {
      final a = makeTracks(10, 'a');
      final b = makeTracks(4, 'b');
      final gate = Completer<PaginatedResult<Track>>();
      Future<PaginatedResult<Track>> slowLoader(int offset) => gate.future;

      await service.playQueue(
        a.take(3).toList(),
        index: 2,
        pending: PendingSource(
          loader: slowLoader,
          nextOffset: 3,
          total: 10,
        ),
      );
      await service.playQueue(b, index: 0);
      gate.complete(pageOf(a, 3));
      await settle();

      expect(
        service.playbackData.queue.tracks.map((t) => t.id),
        equals(b.map((t) => t.id)),
      );
      expect(service.playbackData.pending.isEmpty, isTrue);
    });

    test('next() on the last track extends the queue instead of stopping',
        () async {
      final all = makeTracks(6);
      Future<PaginatedResult<Track>> loader(int offset) async {
        return pageOf(all, offset, limit: 3);
      }

      await service.playQueue(
        all.take(3).toList(),
        index: 2,
        pending: PendingSource(
          loader: loader,
          nextOffset: 3,
          total: 6,
        ),
      );
      await service.next();

      expect(service.playbackData.currentTrack?.id, equals('t3'));
      expect(service.playbackData.queue.length, equals(6));
      verify(() => mockDriver.play()).called(2);
      verifyNever(() => mockDriver.stop());
    });

    test('arrivals are appended literally, repeated ids included', () async {
      final first = makeTracks(5);
      final repeated = createPendingTestTrack('t1', 'Song 1 again');
      final rest = [repeated, ...makeTracks(4, 'n')];
      Future<PaginatedResult<Track>> loader(int offset) async {
        return PaginatedResult<Track>(
          items: rest,
          total: 10,
          offset: offset,
          limit: 5,
        );
      }

      await service.playQueue(
        first,
        index: 4,
        pending: PendingSource(
          loader: loader,
          nextOffset: 5,
          total: 10,
        ),
      );
      await settle();

      final ids = service.playbackData.queue.tracks.map((t) => t.id).toList();
      expect(ids.length, equals(10));
      expect(ids.where((id) => id == 't1').length, equals(2));
    });

    test(
      'completed fill before shuffle keeps the full deck and arrival order',
      () async {
        final all = makeTracks(10);
        Future<PaginatedResult<Track>> loader(int offset) async {
          return pageOf(all, offset, limit: 5);
        }

        await service.playQueue(
          all.take(5).toList(),
          index: 0,
          pending: PendingSource(
            loader: loader,
            nextOffset: 5,
            total: 10,
          ),
        );
        await settle();
        service.toggleShuffle();
        await settle();

        final queue = service.playbackData.queue;
        expect(queue.length, equals(10));
        expect(
          queue.tracks.map((t) => t.id).toSet(),
          equals(all.map((t) => t.id).toSet()),
        );
        expect(
          queue.originalTracks.map((t) => t.id),
          equals(all.map((t) => t.id)),
        );
      },
    );

    test(
      'arrivals during shuffle land after the current track',
      () async {
        final all = makeTracks(10);
        final gate = Completer<PaginatedResult<Track>>();
        Future<PaginatedResult<Track>> loader(int offset) => gate.future;

        await service.playQueue(
          all.take(5).toList(),
          index: 0,
          pending: PendingSource(
            loader: loader,
            nextOffset: 5,
            total: 10,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        service.toggleShuffle();
        await service.skipToIndex(4);
        final currentId = service.playbackData.currentTrack?.id;
        gate.complete(pageOf(all, 5, limit: 5));
        await settle();

        final queue = service.playbackData.queue;
        expect(queue.length, equals(10));
        expect(queue.tracks[queue.currentIndex].id, equals(currentId));
        expect(
          queue.tracks.skip(queue.currentIndex + 1).map((t) => t.id).toSet(),
          containsAll(['t5', 't6', 't7', 't8', 't9']),
        );
        expect(
          queue.originalTracks.skip(5).map((t) => t.id),
          equals(['t5', 't6', 't7', 't8', 't9']),
        );
      },
    );

    test('addToQueue with active pending appends to main and keeps pending',
        () async {
      final all = makeTracks(25);
      final gate = Completer<PaginatedResult<Track>>();
      Future<PaginatedResult<Track>> loader(int offset) => gate.future;
      final extra = createPendingTestTrack('x', 'Extra');

      await service.playQueue(
        all.take(5).toList(),
        index: 0,
        pending: PendingSource(
          loader: loader,
          nextOffset: 5,
          total: 25,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      service.addToQueue(extra);

      expect(service.playbackData.queue.length, equals(6));
      expect(service.playbackData.queue.tracks.last.id, equals('x'));
      expect(service.playbackData.pending.nextOffset, equals(5));

      gate.complete(pageOf(all, 5));
      await settle();
      expect(service.playbackData.queue.length, equals(26));
    });

    test('concurrent pulls share a single flight', () async {
      final all = makeTracks(6);
      final gate = Completer<PaginatedResult<Track>>();
      var calls = 0;
      Future<PaginatedResult<Track>> loader(int offset) async {
        calls++;
        return gate.future;
      }

      await service.playQueue(
        all.take(3).toList(),
        index: 2,
        pending: PendingSource(
          loader: loader,
          nextOffset: 3,
          total: 6,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.playbackData.pending.isLoading, isTrue);

      await service.skipToIndex(1);
      await Future<void>.delayed(Duration.zero);
      expect(calls, equals(1));

      gate.complete(pageOf(all, 3, limit: 3));
      await settle();

      expect(service.playbackData.queue.length, equals(6));
      expect(service.playbackData.pending.isLoading, isFalse);
    });
  });
}
