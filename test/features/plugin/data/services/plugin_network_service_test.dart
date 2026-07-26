import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_request.dart';
import 'package:gyawun_metadata_sdk/metadata/models/plugin_response.dart';
import 'package:music_are/features/plugin/data/services/plugin_network_service.dart';

void main() {
  group('PluginNetworkService Real API Tests', () {
    late PluginNetworkService service;

    setUp(() {
      service = PluginNetworkService();
    });

    test('GET request should return 200 OK from public test API', () async {
      final pluginRequest = PluginRequest(
        url: 'https://jsonplaceholder.typicode.com/posts/1',
        method: 'GET',
      );

      final response = await service.send(pluginRequest);

      // Verify that the response is mapped correctly to our SDK model.
      expect(response, isA<PluginResponse>());
      expect(response.statusCode, equals(200));
      expect(response.body, contains('"userId"'));
      expect(response.body, contains('"id": 1'));
    });

    test(
      'POST request should return 201 Created from public test API',
      () async {
        final pluginRequest = PluginRequest(
          url: 'https://jsonplaceholder.typicode.com/posts',
          method: 'POST',
          body: '{"title": "foo", "body": "bar", "userId": 1}',
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
        );

        final response = await service.send(pluginRequest);

        // Verify that the response is mapped correctly to our SDK model.
        expect(response, isA<PluginResponse>());
        expect(response.statusCode, equals(201));
        expect(response.body, contains('"id": 101'));
      },
    );
  });
}
