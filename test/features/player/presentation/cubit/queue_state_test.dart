import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:music_are/features/player/data/models/playback_repeat_mode.dart';
import 'package:music_are/features/player/presentation/cubit/queue_state.dart';

Track createTestTrack(String id, String name) {
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

void main() {
  group('QueueState Presentation Model Tests', () {
    final track1 = createTestTrack('1', 'Song 1');
    final track2 = createTestTrack('2', 'Song 2');

    test('fromPlaybackQueue maps correctly', () {
      final playbackQueue = const PlaybackQueue().setQueue([
        track1,
        track2,
      ], startIndex: 0);

      final queueState = QueueState.fromPlaybackQueue(playbackQueue);

      expect(queueState.tracks.length, equals(2));
      expect(queueState.currentIndex, equals(0));
      expect(queueState.isShuffled, isFalse);
      expect(queueState.repeatMode, equals(PlaybackRepeatMode.off));
      expect(queueState.hasNext, isTrue);
      expect(queueState.hasPrevious, isFalse);
      expect(queueState.currentTrack, equals(track1));
    });

    test('value equality is supported', () {
      const state1 = QueueState(
        currentIndex: 1,
        hasNext: true,
        isShuffled: true,
      );
      const state2 = QueueState(
        currentIndex: 1,
        hasNext: true,
        isShuffled: true,
      );
      const state3 = QueueState(
        currentIndex: 0,
        hasNext: false,
        isShuffled: false,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
    });
  });
}
