import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_request.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_response.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/services/sdk_services/plugin_network_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('PluginNetworkService Unit Tests', () {
    late MockHttpClient mockClient;
    late PluginNetworkService service;

    setUp(() {
      mockClient = MockHttpClient();
      service = PluginNetworkService(
        client: mockClient,
        maxRetries: 2,
        initialRetryDelay: const Duration(milliseconds: 10),
        requestTimeout: const Duration(milliseconds: 100),
      );
    });

    test('GET request returns 200 OK immediately without retrying', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('{"ok": true}', 200));

      final response = await service.send(
        PluginRequest(url: 'https://example.com', method: 'GET'),
      );

      expect(response, isA<PluginResponse>());
      expect(response.statusCode, equals(200));
      verify(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).called(1);
    });

    test(
      'retries on 503 Service Unavailable and succeeds on second attempt',
      () async {
        int calls = 0;
        when(
          () => mockClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async {
          calls++;
          if (calls == 1) {
            return http.Response('Service Unavailable', 503);
          }
          return http.Response('{"ok": true}', 200);
        });

        final response = await service.send(
          PluginRequest(url: 'https://example.com'),
        );

        expect(response.statusCode, equals(200));
        expect(calls, equals(2));
      },
    );
  });
}
