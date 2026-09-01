import 'package:music_are/features/plugin/audio_source/data/models/audio_quality.dart';

class AudioStreamResponse {
  final String url;
  final AudioQuality quality;
  final String? codec;
  final int? bitrate;
  final int? expiresAt;
  final Map<String, String> headers;

  const AudioStreamResponse({
    required this.url,
    required this.quality,
    this.codec,
    this.bitrate,
    this.expiresAt,
    this.headers = const {},
  });

  factory AudioStreamResponse.fromJson(Map<String, dynamic> json) {
    final qualityStr = json['quality'] as String? ?? 'high';
    final rawHeaders = json['headers'] as Map<String, dynamic>? ?? {};
    final Map<String, String> parsedHeaders = rawHeaders.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return AudioStreamResponse(
      url: json['url'] as String,
      quality: AudioQuality.fromString(qualityStr),
      codec: json['codec'] as String?,
      bitrate: json['bitrate'] as int?,
      expiresAt: json['expiresAt'] as int?,
      headers: parsedHeaders,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'quality': quality.value,
    'codec': codec,
    'bitrate': bitrate,
    'expiresAt': expiresAt,
    'headers': headers,
  };
}
