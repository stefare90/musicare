import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/models/playback_data.dart';
import 'package:music_are/features/player/data/models/playback_processing_state.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:music_are/features/player/data/models/playback_repeat_mode.dart';
import 'package:music_are/features/player/data/services/audio_handler.dart';
import 'package:music_are/features/player/data/services/audio_player_service.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

Track createTrack(String id) {
  return Track(
    id: id,
    name: 'Song $id',
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

PlaybackQueue queueAt(
  int index, {
  int length = 3,
  PlaybackRepeatMode repeatMode = PlaybackRepeatMode.off,
}) {
  final tracks = List.generate(length, (i) => createTrack('$i'));
  return PlaybackQueue(
    tracks: tracks,
    originalTracks: tracks,
    currentIndex: index,
    repeatMode: repeatMode,
  );
}

PlaybackData dataFor(
  PlaybackQueue queue, {
  bool isPlaying = false,
  PlaybackProcessingState processingState = PlaybackProcessingState.ready,
  Duration position = Duration.zero,
}) {
  return PlaybackData(
    queue: queue,
    isPlaying: isPlaying,
    processingState: processingState,
    position: position,
  );
}

Future<void> settle() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  late MockAudioPlayerService service;
  late StreamController<PlaybackData> controller;
  late MusicAreAudioHandler handler;

  setUp(() {
    service = MockAudioPlayerService();
    controller = StreamController<PlaybackData>.broadcast();

    when(() => service.playbackDataStream).thenAnswer((_) => controller.stream);
    when(() => service.play()).thenAnswer((_) async {});
    when(() => service.pause()).thenAnswer((_) async {});
    when(() => service.stop()).thenAnswer((_) async {});
    when(() => service.seek(any())).thenAnswer((_) async {});
    when(() => service.next()).thenAnswer((_) async {});
    when(() => service.previous()).thenAnswer((_) async {});
    when(() => service.skipToIndex(any())).thenAnswer((_) async {});

    handler = MusicAreAudioHandler(service);
  });

  tearDown(() async {
    await handler.dispose();
    await controller.close();
  });

  group('published state', () {
    test('publishes the current media item from the track', () async {
      controller.add(dataFor(queueAt(0)));
      await settle();

      final item = handler.mediaItem.value;
      expect(item, isNotNull);
      expect(item!.id, '0');
      expect(item.title, 'Song 0');
      expect(item.artist, 'Artist');
      expect(item.album, 'Album');
      expect(item.duration, const Duration(milliseconds: 180000));
    });

    test('does not re-publish the media item on position-only updates', () async {
      var emissions = 0;
      handler.mediaItem.listen((item) {
        if (item != null) emissions++;
      });

      controller.add(dataFor(queueAt(1)));
      await settle();
      controller.add(dataFor(queueAt(1), position: const Duration(seconds: 5)));
      await settle();

      expect(emissions, 1);
    });

    test('publishes the queue index and playing flag', () async {
      controller.add(dataFor(queueAt(1), isPlaying: true));
      await settle();

      final state = handler.playbackState.value;
      expect(state.queueIndex, 1);
      expect(state.playing, isTrue);
    });

    test('maps the JIT loading processing state', () async {
      controller.add(
        dataFor(queueAt(0), processingState: PlaybackProcessingState.loading),
      );
      await settle();

      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.loading,
      );
    });

    test('enables previous/next only when the Dart queue allows them', () async {
      controller.add(dataFor(queueAt(1)));
      await settle();

      var actions = handler.playbackState.value.controls
          .map((control) => control.action)
          .toList();
      expect(
        actions,
        containsAll([MediaAction.skipToPrevious, MediaAction.skipToNext]),
      );

      controller.add(dataFor(queueAt(0)));
      await settle();
      actions = handler.playbackState.value.controls
          .map((control) => control.action)
          .toList();
      expect(actions, isNot(contains(MediaAction.skipToPrevious)));
      expect(actions, contains(MediaAction.skipToNext));

      controller.add(dataFor(queueAt(2)));
      await settle();
      actions = handler.playbackState.value.controls
          .map((control) => control.action)
          .toList();
      expect(actions, contains(MediaAction.skipToPrevious));
      expect(actions, isNot(contains(MediaAction.skipToNext)));
    });

    test('respects repeat all when enabling next on the last track', () async {
      controller.add(
        dataFor(queueAt(2, repeatMode: PlaybackRepeatMode.all)),
      );
      await settle();

      final actions = handler.playbackState.value.controls
          .map((control) => control.action)
          .toList();
      expect(actions, contains(MediaAction.skipToNext));
    });

    test('shows play when paused and pause when playing', () async {
      controller.add(dataFor(queueAt(0)));
      await settle();
      expect(
        handler.playbackState.value.controls.map((c) => c.action),
        contains(MediaAction.play),
      );

      controller.add(dataFor(queueAt(0), isPlaying: true));
      await settle();
      expect(
        handler.playbackState.value.controls.map((c) => c.action),
        contains(MediaAction.pause),
      );
    });
  });

  group('delegation to the service', () {
    test('maps transport commands to the service', () async {
      await handler.play();
      await handler.pause();
      await handler.stop();
      await handler.seek(const Duration(seconds: 7));
      await handler.skipToNext();
      await handler.skipToPrevious();
      await handler.skipToQueueItem(2);

      verify(() => service.play()).called(1);
      verify(() => service.pause()).called(1);
      verify(() => service.stop()).called(1);
      verify(() => service.seek(const Duration(seconds: 7))).called(1);
      verify(() => service.next()).called(1);
      verify(() => service.previous()).called(1);
      verify(() => service.skipToIndex(2)).called(1);
    });
  });
}
