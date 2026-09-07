import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';

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
  group('PlaybackQueue Unit Tests', () {
    late PlaybackQueue queue;
    late List<Track> tracks;

    setUp(() {
      queue = PlaybackQueue();
      tracks = [
        createTestTrack('1', 'Song 1'),
        createTestTrack('2', 'Song 2'),
        createTestTrack('3', 'Song 3'),
      ];
    });

    test('initial queue is empty with default settings', () {
      expect(queue.isEmpty, isTrue);
      expect(queue.currentTrack, isNull);
      expect(queue.repeatMode, equals(RepeatMode.off));
      expect(queue.isShuffled, isFalse);
    });

    test('setQueue initializes tracks and sets initial pointer', () {
      queue.setQueue(tracks, startIndex: 1);

      expect(queue.length, equals(3));
      expect(queue.currentIndex, equals(1));
      expect(queue.currentTrack?.name, equals('Song 2'));
      expect(queue.hasNext, isTrue);
      expect(queue.hasPrevious, isTrue);
    });

    test(
      'next advances sequentially and stops at end when RepeatMode is off',
      () {
        queue.setQueue(tracks, startIndex: 1);

        final nextTrack = queue.next();
        expect(nextTrack?.name, equals('Song 3'));
        expect(queue.currentIndex, equals(2));
        expect(queue.hasNext, isFalse);

        final endTrack = queue.next();
        expect(endTrack, isNull);
        expect(queue.currentIndex, equals(2));
      },
    );

    test('next loops back to start when RepeatMode is all', () {
      queue.setQueue(tracks, startIndex: 2);
      queue.setRepeatMode(RepeatMode.all);

      expect(queue.hasNext, isTrue);
      final loopedTrack = queue.next();

      expect(loopedTrack?.name, equals('Song 1'));
      expect(queue.currentIndex, equals(0));
    });

    test('next repeats current track when RepeatMode is one', () {
      queue.setQueue(tracks, startIndex: 1);
      queue.setRepeatMode(RepeatMode.one);

      final repeatedTrack = queue.next();
      expect(repeatedTrack?.name, equals('Song 2'));
      expect(queue.currentIndex, equals(1));
    });

    test('previous moves backward and loops to end when RepeatMode is all', () {
      queue.setQueue(tracks, startIndex: 0);
      queue.setRepeatMode(RepeatMode.all);

      final loopedTrack = queue.previous();
      expect(loopedTrack?.name, equals('Song 3'));
      expect(queue.currentIndex, equals(2));
    });

    test(
      'toggleShuffle maintains current track at index 0 and unshuffle restores original order',
      () {
        queue.setQueue(tracks, startIndex: 1); // Current: Song 2

        queue.toggleShuffle();
        expect(queue.isShuffled, isTrue);
        expect(queue.currentIndex, equals(0));
        expect(queue.currentTrack?.name, equals('Song 2'));
        expect(queue.length, equals(3));

        queue.toggleShuffle();
        expect(queue.isShuffled, isFalse);
        expect(queue.currentTrack?.name, equals('Song 2'));
        expect(queue.currentIndex, equals(1));
        expect(queue.tracks[0].name, equals('Song 1'));
        expect(queue.tracks[1].name, equals('Song 2'));
        expect(queue.tracks[2].name, equals('Song 3'));
      },
    );

    test('cycleRepeatMode transitions off -> all -> one -> off', () {
      expect(queue.cycleRepeatMode(), equals(RepeatMode.all));
      expect(queue.cycleRepeatMode(), equals(RepeatMode.one));
      expect(queue.cycleRepeatMode(), equals(RepeatMode.off));
    });

    test('insertNext places track immediately after current pointer', () {
      queue.setQueue(tracks, startIndex: 0);
      final newTrack = createTestTrack('4', 'Inserted Song');

      queue.insertNext(newTrack);

      expect(queue.length, equals(4));
      expect(queue.tracks[1].name, equals('Inserted Song'));
      expect(queue.currentIndex, equals(0));
    });

    test('reorder correctly repositions track and updates current pointer', () {
      queue.setQueue(tracks, startIndex: 0); // Current: Song 1 at 0

      // Move Song 1 from index 0 to index 2
      queue.reorder(0, 2);

      expect(queue.tracks[2].name, equals('Song 1'));
      expect(queue.currentIndex, equals(2));
    });

    test('removeAt removes track and adjusts current pointer safely', () {
      queue.setQueue(tracks, startIndex: 2); // Current: Song 3 at 2

      queue.removeAt(0); // Remove Song 1

      expect(queue.length, equals(2));
      expect(queue.currentIndex, equals(1));
      expect(queue.currentTrack?.name, equals('Song 3'));
    });
  });
}
