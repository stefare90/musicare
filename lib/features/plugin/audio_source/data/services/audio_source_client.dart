import 'dart:convert';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:http/http.dart' as http;
import 'package:music_are/features/plugin/audio_source/data/models/audio_quality.dart';
import 'package:music_are/features/plugin/audio_source/data/models/audio_stream_response.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class AudioSourceClient {
  final http.Client _httpClient;
  int? _port;

  AudioSourceClient({http.Client? httpClient, this._port})
    : _httpClient = httpClient ?? http.Client();

  int? get port => _port;
  bool get isConfigured => _port != null;

  void setPort(int port) {
    _port = port;
  }

  void reset() {
    _port = null;
  }

  Future<bool> ping({Duration timeout = const Duration(seconds: 2)}) async {
    if (_port == null) return false;
    try {
      final response = await _httpClient
          .get(Uri.parse('http://127.0.0.1:$_port/ping'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<AudioStreamResponse>> getStream({
    required Track track,
    AudioQuality quality = AudioQuality.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_port == null) {
      throw PluginNotLoadedException();
    }

    final payload = {
      'track': {
        'name': track.name,
        'artists': track.artists.map((a) => {'name': a.name}).toList(),
        'durationMs': track.durationMs,
      },
      'quality': quality.value,
    };

    final response = await _httpClient
        .post(
          Uri.parse('http://127.0.0.1:$_port/get_stream'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw AudioSourceStreamResolutionException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! List) {
      throw AudioSourceStreamResolutionException(
        statusCode: response.statusCode,
        message: 'Expected JSON array of streams, received: $data',
      );
    }

    return data
        .map(
          (item) => AudioStreamResponse.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
