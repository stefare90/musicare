import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/player/data/models/pending_source.dart';
import 'package:music_are/features/player/data/models/playback_pending.dart';

void main() {
  group('PlaybackPending transitions', () {
    PendingSource source() => PendingSource(
      loader: (_) async => throw UnimplementedError(),
      nextOffset: 5,
      total: 25,
    );

    test('fromSource seeds offsets without loading or error', () {
      final pending = PlaybackPending.fromSource(source());

      expect(pending.nextOffset, equals(5));
      expect(pending.total, equals(25));
      expect(pending.isLoading, isFalse);
      expect(pending.error, isNull);
      expect(pending.isEmpty, isFalse);
    });

    test('started keeps offsets, flags loading and clears the error', () {
      const failed = PlaybackPending(
        nextOffset: 5,
        total: 25,
        error: 'boom',
      );

      final started = failed.started();

      expect(started.nextOffset, equals(5));
      expect(started.total, equals(25));
      expect(started.isLoading, isTrue);
      expect(started.error, isNull);
    });

    test('advancedBy moves the offset and clears loading', () {
      const pending = PlaybackPending(
        nextOffset: 5,
        total: 25,
        isLoading: true,
      );

      final advanced = pending.advancedBy(loaded: 10, total: 25);

      expect(advanced.nextOffset, equals(15));
      expect(advanced.total, equals(25));
      expect(advanced.isLoading, isFalse);
      expect(advanced.isEmpty, isFalse);
    });

    test('advancedBy past the end collapses to empty', () {
      const pending = PlaybackPending(nextOffset: 20, total: 25);

      final advanced = pending.advancedBy(loaded: 20, total: 25);

      expect(advanced, equals(const PlaybackPending.empty()));
    });

    test('failed keeps offsets and records the error', () {
      const pending = PlaybackPending(nextOffset: 5, total: 25);

      final failed = pending.failed('boom');

      expect(failed.nextOffset, equals(5));
      expect(failed.total, equals(25));
      expect(failed.isLoading, isFalse);
      expect(failed.error, equals('boom'));
    });

    test('empty reports nothing left', () {
      expect(const PlaybackPending.empty().isEmpty, isTrue);
      expect(
        const PlaybackPending(nextOffset: 3, total: 3).isEmpty,
        isTrue,
      );
      expect(
        const PlaybackPending(nextOffset: 2, total: 3).isEmpty,
        isFalse,
      );
    });
  });
}
