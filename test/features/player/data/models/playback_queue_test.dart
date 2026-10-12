import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/player/data/models/playback_queue.dart';
import 'package:music_are/features/player/data/models/playback_repeat_mode.dart';

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
  group('PlaybackQueue Immutable Model Unit Tests', () {
    late PlaybackQueue queue;
    late List<Track> tracks;

    setUp(() {
      queue = const PlaybackQueue();
      tracks = [
        createTestTrack('1', 'Song 1'),
        createTestTrack('2', 'Song 2'),
        createTestTrack('3', 'Song 3'),
      ];
    });

    test('initial queue is empty with default settings', () {
      expect(queue.isEmpty, isTrue);
      expect(queue.currentTrack, isNull);
      expect(queue.repeatMode, equals(PlaybackRepeatMode.off));
      expect(queue.isShuffled, isFalse);
    });

    test('setQueue returns new queue and sets initial pointer', () {
      final updated = queue.setQueue(tracks, startIndex: 1);

      expect(updated.length, equals(3));
      expect(updated.currentIndex, equals(1));
      expect(updated.currentTrack?.name, equals('Song 2'));
      expect(updated.hasNext, isTrue);
      expect(updated.hasPrevious, isTrue);
    });

    test(
      'next advances sequentially and returns null at end when PlaybackRepeatMode is off',
      () {
        final initial = queue.setQueue(tracks, startIndex: 1);

        final nextQueue = initial.next();
        expect(nextQueue?.currentTrack?.name, equals('Song 3'));
        expect(nextQueue?.currentIndex, equals(2));
        expect(nextQueue?.hasNext, isFalse);

        final endQueue = nextQueue?.next();
        expect(endQueue, isNull);
      },
    );

    test('next loops back to start when PlaybackRepeatMode is all', () {
      final initial = queue
          .setQueue(tracks, startIndex: 2)
          .setRepeatMode(PlaybackRepeatMode.all);

      expect(initial.hasNext, isTrue);
      final looped = initial.next();

      expect(looped?.currentTrack?.name, equals('Song 1'));
      expect(looped?.currentIndex, equals(0));
    });

    test('next repeats current track when PlaybackRepeatMode is one', () {
      final initial = queue
          .setQueue(tracks, startIndex: 1)
          .setRepeatMode(PlaybackRepeatMode.one);

      final repeated = initial.next();
      expect(repeated?.currentTrack?.name, equals('Song 2'));
      expect(repeated?.currentIndex, equals(1));
    });

    test('previous moves backward and loops to end when PlaybackRepeatMode is all', () {
      final initial = queue
          .setQueue(tracks, startIndex: 0)
          .setRepeatMode(PlaybackRepeatMode.all);

      final looped = initial.previous();
      expect(looped?.currentTrack?.name, equals('Song 3'));
      expect(looped?.currentIndex, equals(2));
    });

    test('jumpToIndex sets current index when in range', () {
      final initial = queue.setQueue(tracks, startIndex: 0);

      final jumped = initial.jumpToIndex(2);
      expect(jumped?.currentTrack?.name, equals('Song 3'));
      expect(jumped?.currentIndex, equals(2));

      final invalid = initial.jumpToIndex(10);
      expect(invalid, isNull);
    });

    test(
      'toggleShuffle maintains current track at index 0 and unshuffle restores original order',
      () {
        final initial = queue.setQueue(
          tracks,
          startIndex: 1,
        ); // Current: Song 2

        final shuffled = initial.toggleShuffle();
        expect(shuffled.isShuffled, isTrue);
        expect(shuffled.currentIndex, equals(0));
        expect(shuffled.currentTrack?.name, equals('Song 2'));
        expect(shuffled.length, equals(3));

        final unshuffled = shuffled.toggleShuffle();
        expect(unshuffled.isShuffled, isFalse);
        expect(unshuffled.currentTrack?.name, equals('Song 2'));
        expect(unshuffled.currentIndex, equals(1));
        expect(unshuffled.tracks[0].name, equals('Song 1'));
        expect(unshuffled.tracks[1].name, equals('Song 2'));
        expect(unshuffled.tracks[2].name, equals('Song 3'));
      },
    );

    test('cycleRepeatMode transitions off -> all -> one -> off', () {
      final all = queue.cycleRepeatMode();
      expect(all.repeatMode, equals(PlaybackRepeatMode.all));

      final one = all.cycleRepeatMode();
      expect(one.repeatMode, equals(PlaybackRepeatMode.one));

      final off = one.cycleRepeatMode();
      expect(off.repeatMode, equals(PlaybackRepeatMode.off));
    });

    test('add appends track to end of queue', () {
      final initial = queue.setQueue(tracks, startIndex: 0);
      final newTrack = createTestTrack('4', 'Song 4');

      final updated = initial.add(newTrack);

      expect(updated.length, equals(4));
      expect(updated.tracks.last.name, equals('Song 4'));
      expect(updated.originalTracks.last.name, equals('Song 4'));
    });

    test('insertNext places track immediately after current pointer', () {
      final initial = queue.setQueue(tracks, startIndex: 0);
      final newTrack = createTestTrack('4', 'Inserted Song');

      final updated = initial.insertNext(newTrack);

      expect(updated.length, equals(4));
      expect(updated.tracks[1].name, equals('Inserted Song'));
      expect(updated.currentIndex, equals(0));
    });

    test('two insertNext calls queue in call order after current', () {
      final initial = queue.setQueue(tracks, startIndex: 0);

      final updated = initial
          .insertNext(createTestTrack('4', 'First'))
          .insertNext(createTestTrack('5', 'Second'));

      expect(updated.length, equals(5));
      expect(updated.tracks[1].name, equals('Second'));
      expect(updated.tracks[2].name, equals('First'));
      expect(updated.currentIndex, equals(0));
    });

    test('addAll appends the block in order to both lists', () {
      final initial = queue.setQueue(tracks, startIndex: 0);

      final updated = initial.addAll([
        createTestTrack('4', 'Song 4'),
        createTestTrack('5', 'Song 5'),
      ]);

      expect(updated.length, equals(5));
      expect(updated.tracks[3].name, equals('Song 4'));
      expect(updated.tracks[4].name, equals('Song 5'));
      expect(updated.originalTracks[3].name, equals('Song 4'));
      expect(updated.originalTracks[4].name, equals('Song 5'));
      expect(updated.currentIndex, equals(0));
    });

    test('insertAllNext places the block right after current, in order',
        () {
      final initial = queue.setQueue(tracks, startIndex: 0);

      final updated = initial.insertAllNext([
        createTestTrack('4', 'First'),
        createTestTrack('5', 'Second'),
      ]);

      expect(updated.length, equals(5));
      expect(updated.tracks[1].name, equals('First'));
      expect(updated.tracks[2].name, equals('Second'));
      expect(updated.originalTracks[3].name, equals('First'));
      expect(updated.originalTracks[4].name, equals('Second'));
      expect(updated.currentIndex, equals(0));
    });

    test('insertAllNext on an empty queue appends', () {
      final updated = queue.insertAllNext([
        createTestTrack('4', 'First'),
        createTestTrack('5', 'Second'),
      ]);

      expect(updated.length, equals(2));
      expect(updated.tracks[0].name, equals('First'));
      expect(updated.tracks[1].name, equals('Second'));
    });

    test('reorder correctly repositions track and updates current pointer', () {
      final initial = queue.setQueue(
        tracks,
        startIndex: 0,
      ); // Current: Song 1 at 0

      // Move Song 1 from index 0 to index 2
      final reordered = initial.reorder(0, 2);

      expect(reordered.tracks[2].name, equals('Song 1'));
      expect(reordered.currentIndex, equals(2));
    });

    test('removeAt removes track and adjusts current pointer safely', () {
      final initial = queue.setQueue(
        tracks,
        startIndex: 2,
      ); // Current: Song 3 at 2

      final updated = initial.removeAt(0); // Remove Song 1

      expect(updated.length, equals(2));
      expect(updated.currentIndex, equals(1));
      expect(updated.currentTrack?.name, equals('Song 3'));
    });

    test(
      'removeAt handles duplicate tracks without removing other instances',
      () {
        final duplicateSong1 = createTestTrack('1', 'Song 1');
        final duplicateQueueTracks = [
          tracks[0], // Song 1 (id: 1)
          tracks[1], // Song 2 (id: 2)
          duplicateSong1, // Song 1 duplicate (id: 1)
        ];

        final initial = queue.setQueue(duplicateQueueTracks, startIndex: 1);

        // Remove the first instance of Song 1 at index 0
        final updated = initial.removeAt(0);

        expect(updated.length, equals(2));
        expect(updated.tracks[0].name, equals('Song 2'));
        expect(updated.tracks[1].name, equals('Song 1'));
        expect(updated.originalTracks.length, equals(2));
        expect(updated.originalTracks.last.name, equals('Song 1'));
      },
    );

    test('clear empties all tracks and resets queue', () {
      final initial = queue.setQueue(tracks, startIndex: 1);
      final cleared = initial.clear();

      expect(cleared.isEmpty, isTrue);
      expect(cleared.currentTrack, isNull);
      expect(cleared.currentIndex, equals(0));
      expect(cleared.isShuffled, isFalse);
    });

    test('operator == and hashCode support value equality', () {
      final q1 = queue.setQueue(tracks, startIndex: 1);
      final q2 = queue.setQueue(tracks, startIndex: 1);

      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));
    });
  });
}
