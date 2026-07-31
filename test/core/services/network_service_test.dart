import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/services/network_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('NetworkService Unit Tests', () {
    late MockHttpClient mockHttpClient;
    late NetworkService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      service = NetworkService(client: mockHttpClient);
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    test(
      'get appends default User-Agent header and performs GET request',
      () async {
        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('{"status": "ok"}', 200));

        final uri = Uri.parse('https://api.github.com');
        final response = await service.get(uri);

        expect(response.statusCode, equals(200));
        expect(response.body, equals('{"status": "ok"}'));

        verify(
          () =>
              mockHttpClient.get(uri, headers: {'User-Agent': 'MusicAre-App'}),
        ).called(1);
      },
    );

    test('get merges custom headers with default User-Agent header', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('{"status": "ok"}', 200));

      final uri = Uri.parse('https://api.github.com');
      await service.get(uri, headers: {'Accept': 'application/json'});

      verify(
        () => mockHttpClient.get(
          uri,
          headers: {'User-Agent': 'MusicAre-App', 'Accept': 'application/json'},
        ),
      ).called(1);
    });
  });
}
