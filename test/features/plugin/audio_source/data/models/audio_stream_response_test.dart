import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/audio_source/data/models/audio_quality.dart';
import 'package:music_are/features/plugin/audio_source/data/models/audio_stream_response.dart';

void main() {
  group('AudioStreamResponse Model Tests', () {
    test('fromJson correctly parses stream response with headers', () {
      final json = {
        'url': 'https://rr1---sn.googlevideo.com/videoplayback?id=123',
        'quality': 'high',
        'codec': 'm4a',
        'bitrate': 160000,
        'expiresAt': 1750000000000,
        'headers': {'User-Agent': 'Mozilla/5.0'},
      };

      final stream = AudioStreamResponse.fromJson(json);

      expect(stream.url, contains('googlevideo.com'));
      expect(stream.quality, equals(AudioQuality.high));
      expect(stream.codec, equals('m4a'));
      expect(stream.bitrate, equals(160000));
      expect(stream.expiresAt, equals(1750000000000));
      expect(stream.headers['User-Agent'], equals('Mozilla/5.0'));
    });
  });
}
