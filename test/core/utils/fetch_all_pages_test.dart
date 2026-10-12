import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/utils/fetch_all_pages.dart';

void main() {
  group('fetchAllPages', () {
    Track song(String id) => Track(
      id: id,
      name: 'Song $id',
      externalUri: '',
      artists: const [],
      album: const Album(
        id: 'al1',
        name: 'Album',
        artists: [],
        releaseDate: '',
        externalUri: '',
        totalTracks: 1,
        albumType: AlbumType.album,
      ),
      durationMs: 1000,
    );

    test('concatenates every page in order', () async {
      final calls = <int>[];
      final all = await fetchAllPages((offset, limit) async {
        calls.add(offset);
        if (offset == 0) {
          return PaginatedResult(items: [song('t1')], total: 3, offset: 0, limit: limit);
        }
        return PaginatedResult(
          items: [song('t2'), song('t3')],
          total: 3,
          offset: offset,
          limit: limit,
        );
      });

      expect(all.map((t) => t.id), ['t1', 't2', 't3']);
      expect(calls, [0, 1]);
    });

    test('stops on an empty page before reaching the total', () async {
      var calls = 0;
      final all = await fetchAllPages((offset, limit) async {
        calls++;
        if (offset == 0) {
          return PaginatedResult(items: [song('t1')], total: 9, offset: 0, limit: limit);
        }
        return PaginatedResult(items: const [], total: 9, offset: offset, limit: limit);
      });

      expect(all.map((t) => t.id), ['t1']);
      expect(calls, 2);
    });

    test('rethrows a page failure for the caller to map', () async {
      final failure = Exception('boom');
      Object? caught;
      try {
        await fetchAllPages((offset, limit) async {
          if (offset == 0) {
            return PaginatedResult(items: [song('t1')], total: 2, offset: 0, limit: limit);
          }
          throw failure;
        });
      } catch (e) {
        caught = e;
      }
      expect(caught, same(failure));
    });
  });
}
