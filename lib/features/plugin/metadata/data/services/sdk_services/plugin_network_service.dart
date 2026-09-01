import 'dart:async';
import 'package:gyawun_metadata_sdk/metadata/interfaces/inetwork_service.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_request.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_response.dart';
import 'package:http/http.dart' as http;

class PluginNetworkService implements INetworkService {
  final http.Client _client;
  final int maxRetries;
  final Duration initialRetryDelay;
  final Duration requestTimeout;

  PluginNetworkService({
    http.Client? client,
    this.maxRetries = 2,
    this.initialRetryDelay = const Duration(seconds: 1),
    this.requestTimeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  @override
  Future<PluginResponse> send(PluginRequest request) async {
    final finalHeaders = {'User-Agent': 'MusicAre/1.0.0'}
      ..addAll(request.headers);

    final uri = Uri.parse(request.url);
    final method = request.method.toUpperCase();

    int attempt = 0;
    Duration currentDelay = initialRetryDelay;

    while (true) {
      attempt++;
      try {
        final http.Response response = await _executeRequest(
          method: method,
          uri: uri,
          headers: finalHeaders,
          body: request.body,
        ).timeout(requestTimeout);

        final statusCode = response.statusCode;
        final isTransientStatus = statusCode >= 500 || statusCode == 429;

        if (isTransientStatus && attempt <= maxRetries) {
          final retryAfterSeconds = _parseRetryAfter(
            response.headers['retry-after'],
          );
          final delay = retryAfterSeconds != null
              ? Duration(seconds: retryAfterSeconds)
              : currentDelay;

          await Future.delayed(delay);
          currentDelay *= 2;
          continue;
        }

        return PluginResponse(statusCode: statusCode, body: response.body);
      } catch (e) {
        if (attempt > maxRetries) {
          rethrow;
        }
        await Future.delayed(currentDelay);
        currentDelay *= 2;
      }
    }
  }

  Future<http.Response> _executeRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    switch (method) {
      case 'POST':
        return _client.post(uri, headers: headers, body: body);
      case 'PUT':
        return _client.put(uri, headers: headers, body: body);
      case 'DELETE':
        return _client.delete(uri, headers: headers, body: body);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: body);
      case 'HEAD':
        return _client.head(uri, headers: headers);
      case 'GET':
      default:
        return _client.get(uri, headers: headers);
    }
  }

  int? _parseRetryAfter(String? headerValue) {
    if (headerValue == null || headerValue.isEmpty) return null;
    return int.tryParse(headerValue);
  }
}
