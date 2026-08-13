import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_request.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_response.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/data/services/sdk_services/plugin_network_service.dart';

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
        initialRetryDelay: const Duration(milliseconds: 10), // Veloce nei test
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
      expect(response.body, contains('"ok": true'));
      verify(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).called(1);
    });

    test('POST, PUT, DELETE, PATCH, HEAD methods dispatch correctly', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('posted', 201));
      when(
        () => mockClient.put(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('put', 200));
      when(
        () => mockClient.delete(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('deleted', 200));
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('patched', 200));
      when(
        () => mockClient.head(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('', 200));

      final postRes = await service.send(
        PluginRequest(url: 'https://example.com', method: 'POST', body: 'data'),
      );
      final putRes = await service.send(
        PluginRequest(url: 'https://example.com', method: 'PUT', body: 'data'),
      );
      final delRes = await service.send(
        PluginRequest(url: 'https://example.com', method: 'DELETE'),
      );
      final patchRes = await service.send(
        PluginRequest(
          url: 'https://example.com',
          method: 'PATCH',
          body: 'data',
        ),
      );
      final headRes = await service.send(
        PluginRequest(url: 'https://example.com', method: 'HEAD'),
      );

      expect(postRes.statusCode, equals(201));
      expect(putRes.statusCode, equals(200));
      expect(delRes.statusCode, equals(200));
      expect(patchRes.statusCode, equals(200));
      expect(headRes.statusCode, equals(200));
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
        verify(
          () => mockClient.get(any(), headers: any(named: 'headers')),
        ).called(2);
      },
    );

    test('respects Retry-After header on 429 Too Many Requests', () async {
      int calls = 0;
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          return http.Response(
            'Rate Limited',
            429,
            headers: {'retry-after': '1'},
          );
        }
        return http.Response('{"ok": true}', 200);
      });

      final response = await service.send(
        PluginRequest(url: 'https://example.com'),
      );

      expect(response.statusCode, equals(200));
      expect(calls, equals(2));
    });

    test('retries on network exceptions and succeeds on retry', () async {
      int calls = 0;
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          throw const SocketException('Connection failed');
        }
        return http.Response('{"ok": true}', 200);
      });

      final response = await service.send(
        PluginRequest(url: 'https://example.com'),
      );

      expect(response.statusCode, equals(200));
      expect(calls, equals(2));
    });

    test(
      'exhausts all retries on persistent 503 and returns final 503 response',
      () async {
        when(
          () => mockClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('Service Unavailable', 503));

        final response = await service.send(
          PluginRequest(url: 'https://example.com'),
        );

        expect(response.statusCode, equals(503));
        verify(
          () => mockClient.get(any(), headers: any(named: 'headers')),
        ).called(3); // 1 iniziale + 2 retry
      },
    );

    test(
      'rethrows TimeoutException when request times out past maxRetries',
      () async {
        when(
          () => mockClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 300));
          return http.Response('Late response', 200);
        });

        expect(
          () async =>
              await service.send(PluginRequest(url: 'https://example.com')),
          throwsA(isA<TimeoutException>()),
        );
      },
    );
  });
}
