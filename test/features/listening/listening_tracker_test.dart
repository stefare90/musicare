import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/listening/data/services/listen_sink.dart';
import 'package:music_are/features/listening/data/services/listening_tracker.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';

class RecordingSink implements ListenSink {
  final List<ListenEvent> events = <ListenEvent>[];
  Object? error;

  List<ListenEvent> get singles =>
      events.where((event) => event.kind == ListenKind.single).toList();

  List<ListenEvent> get playingNow =>
      events.where((event) => event.kind == ListenKind.playingNow).toList();

  @override
  Future<void> submit(ListenEvent event) async {
    if (error != null) throw error!;
    events.add(event);
  }
}

class FakeClock {
  FakeClock(this.current);

  DateTime current;
  late final Clock clock = Clock(() => current);

  void advance(Duration duration) => current = current.add(duration);
}

Track testTrack({String id = 't1', int durationMs = 180000}) {
  return Track(
    id: id,
    name: 'Track $id',
    externalUri: '',
    artists: [Artist(id: 'artist', name: 'Artist', externalUri: '')],
    album: Album(
      id: 'album',
      name: 'Album',
      artists: const [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 10,
      albumType: AlbumType.album,
    ),
    durationMs: durationMs,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<PlaybackData> controller;
  late FakeClock clock;
  late RecordingSink sink;
  late ListeningTracker tracker;

  setUp(() {
    controller = StreamController<PlaybackData>.broadcast();
    clock = FakeClock(DateTime.utc(2026, 11, 9, 12));
    sink = RecordingSink();
    // The listener captures the zone, so the tracker reads the fake clock.
    withClock(
      clock.clock,
      () => tracker = ListeningTracker(
        playback: controller.stream,
        sinks: [sink],
      )..start(),
    );
  });

  tearDown(() async {
    await tracker.dispose();
    await controller.close();
  });

  Future<void> emit(
    Track track,
    Duration position, {
    bool playing = true,
    PlaybackProcessingState state = PlaybackProcessingState.ready,
  }) async {
    controller.add(
      PlaybackData(
        queue: PlaybackQueue().setQueue([track]),
        isPlaying: playing,
        processingState: state,
        position: position,
        duration: Duration(milliseconds: track.durationMs),
      ),
    );
    await pumpEventQueue();
  }

  /// Seeds a playback instance and then plays [seconds] one-second ticks.
  Future<void> play(
    Track track,
    int seconds, {
    int fromSeconds = 0,
    bool seed = false,
  }) async {
    if (seed) await emit(track, Duration.zero);
    for (var s = fromSeconds + 1; s <= fromSeconds + seconds; s++) {
      clock.advance(const Duration(seconds: 1));
      await emit(track, Duration(seconds: s));
    }
  }

  group('thresholds', () {
    test('a listen counts at half the track', () async {
      final track = testTrack();
      await play(track, 89, seed: true);
      expect(sink.singles, isEmpty);

      await play(track, 1, fromSeconds: 89);
      expect(sink.singles, hasLength(1));
      expect(
        sink.singles.single.listenedAt,
        clock.current.subtract(const Duration(seconds: 90)),
      );
      expect(sink.singles.single.track, same(track));
    });

    test('a long track counts at four minutes, not at its half', () async {
      final track = testTrack(durationMs: 1200000);
      await play(track, 239, seed: true);
      expect(sink.singles, isEmpty);

      await play(track, 1, fromSeconds: 239);
      expect(sink.singles, hasLength(1));
    });

    test('a track shorter than 30 seconds never counts', () async {
      final track = testTrack(durationMs: 20000);
      await play(track, 20, seed: true);

      expect(sink.singles, isEmpty);
      expect(sink.playingNow, hasLength(1));
    });

    test('an early skip produces no listen', () async {
      final first = testTrack();
      final second = testTrack(id: 't2');

      await play(first, 5, seed: true);
      await play(second, 1, seed: true);

      expect(sink.singles, isEmpty);
    });
  });

  group('time actually played', () {
    test('a forward seek does not count', () async {
      final track = testTrack(durationMs: 40000);
      await play(track, 5, seed: true);

      await emit(track, const Duration(seconds: 600));
      expect(sink.singles, isEmpty);

      await play(track, 14, fromSeconds: 600);
      expect(sink.singles, isEmpty);

      await play(track, 1, fromSeconds: 614);
      expect(sink.singles, hasLength(1));
    });

    test('a backward seek does not count', () async {
      final track = testTrack(durationMs: 40000);
      await play(track, 10, seed: true);

      await emit(track, Duration.zero);
      await play(track, 9);
      expect(sink.singles, isEmpty);

      await play(track, 1, fromSeconds: 9);
      expect(sink.singles, hasLength(1));
    });

    test('a short pause is not counted and does not resend playing now',
        () async {
      final track = testTrack(durationMs: 40000);
      await play(track, 5, seed: true);

      await emit(track, const Duration(seconds: 5), playing: false);
      clock.advance(const Duration(seconds: 2));
      await emit(track, const Duration(seconds: 5));

      expect(sink.playingNow, hasLength(1));

      await play(track, 14, fromSeconds: 5);
      expect(sink.singles, isEmpty);

      await play(track, 1, fromSeconds: 19);
      expect(sink.singles, hasLength(1));
    });

    test('a pause longer than five seconds resends playing now', () async {
      final track = testTrack(durationMs: 40000);
      await play(track, 5, seed: true);

      await emit(track, const Duration(seconds: 5), playing: false);
      clock.advance(const Duration(seconds: 6));
      await emit(track, const Duration(seconds: 5));

      expect(sink.playingNow, hasLength(2));
      expect(sink.playingNow.last.listenedAt, isNull);
    });
  });

  group('repeat and dedupe', () {
    test('repeat-one produces a second listen with a new start', () async {
      final track = testTrack(durationMs: 40000);
      await play(track, 20, seed: true);
      expect(sink.singles, hasLength(1));

      clock.advance(const Duration(seconds: 1));
      await emit(
        track,
        Duration.zero,
        playing: false,
        state: PlaybackProcessingState.loading,
      );
      await play(track, 20);

      expect(sink.singles, hasLength(2));
      expect(
        sink.singles.last.listenedAt!.isAfter(sink.singles.first.listenedAt!),
        isTrue,
      );
      expect(sink.playingNow, hasLength(2));
    });

    test('a restart at the same start instant is deduped', () async {
      final start = clock.current;
      final track = testTrack(durationMs: 40000);
      await play(track, 20, seed: true);
      expect(sink.singles, hasLength(1));

      clock.current = start;
      await emit(
        track,
        Duration.zero,
        playing: false,
        state: PlaybackProcessingState.loading,
      );
      await play(track, 20);

      expect(sink.singles, hasLength(1));
    });

    test('playing now is sent once per instance', () async {
      final track = testTrack();
      await play(track, 10, seed: true);

      expect(sink.playingNow, hasLength(1));
      expect(sink.playingNow.single.track.id, track.id);
    });

    test('an emptied queue resets the instance', () async {
      final first = testTrack();
      final second = testTrack(id: 't2');
      await play(first, 3, seed: true);

      controller.add(const PlaybackData());
      await pumpEventQueue();

      await play(second, 1, seed: true);
      expect(sink.playingNow.last.track.id, 't2');
    });
  });

  group('isolation', () {
    test('a sink that throws does not stop the others or the tracker',
        () async {
      final failing = RecordingSink()..error = Exception('broken sink');
      final healthy = RecordingSink();
      final isolated = ListeningTracker(
        playback: controller.stream,
        sinks: [failing, healthy],
      )..start();
      addTearDown(isolated.dispose);

      await play(testTrack(), 3, seed: true);

      expect(healthy.playingNow, hasLength(1));
      expect(healthy.events, isNotEmpty);
    });

    test('after dispose no event is delivered', () async {
      final track = testTrack();
      await play(track, 1, seed: true);
      final delivered = sink.events.length;

      await tracker.dispose();
      await play(track, 1, fromSeconds: 1);

      expect(sink.events, hasLength(delivered));
    });
  });
}
