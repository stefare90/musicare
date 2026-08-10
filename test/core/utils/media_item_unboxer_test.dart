import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/utils/media_item_unboxer.dart';
import 'package:dart_eval/stdlib/core.dart';

void main() {
  group('mediaItemUnboxer', () {
    test('unboxes a dart_eval \$Value', () {
      final value = $String('test');
      expect(unboxMediaItem(value), equals('test'));
    });

    test('returns plain objects as is', () {
      expect(unboxMediaItem('test'), equals('test'));
    });

    test('throws ArgumentError on null', () {
      expect(() => unboxMediaItem(null), throwsArgumentError);
    });
  });
}
