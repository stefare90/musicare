import 'package:http/http.dart' as http;

class NetworkService {
  final http.Client _client;

  NetworkService({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(
      url,
      headers: {'User-Agent': 'MusicAre-App', ...?headers},
    );
  }
}
