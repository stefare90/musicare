import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/services/network_service.dart';
import 'package:music_are/features/plugin/catalog/data/services/github_topic_catalog.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class MockNetworkService extends Mock implements NetworkService {}

Uint8List createPluginZip({
  required String id,
  required String type,
  String version = '1.0.0',
}) {
  final archive = Archive();
  final jsonBytes = utf8.encode(
    jsonEncode({
      'id': id,
      'packageId': '${id}_package',
      'type': type,
      'name': id,
      'version': version,
      'pluginSdkVersion': '1.0.0',
      'author': 'Tester',
      'description': 'Test plugin',
    }),
  );
  archive.addFile(ArchiveFile('plugin.json', jsonBytes.length, jsonBytes));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  const searchUri = 'https://api.github.com/search/repositories?q=topic:musicare-plugin';
  const metadataRepo = 'owner/metadata-plugin';
  const audioRepo = 'owner/audio-plugin';
  const metadataRelease =
      'https://api.github.com/repos/$metadataRepo/releases/latest';
  const audioRelease =
      'https://api.github.com/repos/$audioRepo/releases/latest';
  const metadataZip = 'https://github.com/$metadataRepo/releases/v1.zip';
  const audioZip = 'https://github.com/$audioRepo/releases/v1.zip';

  late MockNetworkService network;
  late GitHubTopicCatalog catalog;
  late DateTime now;
  late Uint8List metadataBytes;
  late Uint8List audioBytes;

  setUp(() {
    network = MockNetworkService();
    now = DateTime(2026, 10, 26, 12);
    catalog = GitHubTopicCatalog(
      networkService: network,
      now: () => now,
    );
    metadataBytes = createPluginZip(
      id: 'org.musicare.metadata.test',
      type: 'metadata',
    );
    audioBytes = createPluginZip(
      id: 'org.musicare.audiosource.test',
      type: 'audioSource',
    );

    when(() => network.get(Uri.parse(searchUri))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'items': [
            {'full_name': metadataRepo},
            {'full_name': audioRepo},
          ],
        }),
        200,
      ),
    );
    when(() => network.get(Uri.parse(metadataRelease))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'assets': [
            {'name': 'metadata.zip', 'browser_download_url': metadataZip},
          ],
        }),
        200,
      ),
    );
    when(() => network.get(Uri.parse(audioRelease))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'assets': [
            {'name': 'audio.zip', 'browser_download_url': audioZip},
          ],
        }),
        200,
      ),
    );
    when(
      () => network.get(Uri.parse(metadataZip)),
    ).thenAnswer((_) async => http.Response.bytes(metadataBytes, 200));
    when(
      () => network.get(Uri.parse(audioZip)),
    ).thenAnswer((_) async => http.Response.bytes(audioBytes, 200));
  });

  test('latest fetches releases once and filters by type', () async {
    final metadata = await catalog.latest(PluginType.metadata);

    expect(metadata.keys, ['org.musicare.metadata.test']);
    expect(metadata.values.single.name, 'org.musicare.metadata.test');

    final audio = await catalog.latest(PluginType.audioSource);
    expect(audio.keys, ['org.musicare.audiosource.test']);

    verify(() => network.get(Uri.parse(searchUri))).called(1);
    verify(() => network.get(Uri.parse(metadataRelease))).called(1);
  });

  test('latest reuses the in-memory cache within the TTL', () async {
    await catalog.latest(PluginType.metadata);
    now = now.add(const Duration(hours: 5, minutes: 59));
    await catalog.latest(PluginType.metadata);

    verify(() => network.get(Uri.parse(searchUri))).called(1);
  });

  test('latest refetches after the TTL expires', () async {
    await catalog.latest(PluginType.metadata);
    now = now.add(GitHubTopicCatalog.cacheTtl);
    await catalog.latest(PluginType.metadata);

    verify(() => network.get(Uri.parse(searchUri))).called(2);
  });

  test('forceRefresh bypasses a fresh cache', () async {
    await catalog.latest(PluginType.metadata);
    await catalog.latest(PluginType.metadata, forceRefresh: true);

    verify(() => network.get(Uri.parse(searchUri))).called(2);
  });

  test('download returns the bytes fetched with the latest release', () async {
    final metadata = await catalog.latest(PluginType.metadata);
    final manifest = metadata.values.single;
    verify(() => network.get(Uri.parse(metadataZip))).called(1);

    final bytes = await catalog.download(manifest);

    expect(bytes, metadataBytes);
    verifyNever(() => network.get(Uri.parse(metadataZip)));
  });

  test('download falls back to the release asset for an uncached manifest', () async {
    final manifest = PluginManifest(
      id: 'org.musicare.metadata.installed',
      packageId: 'installed',
      type: 'metadata',
      name: 'Installed',
      version: '3.0.3',
      pluginSdkVersion: '6.0.0',
      author: 'Tester',
      description: 'Installed',
      repository: 'https://github.com/owner/repo',
    );
    final uri = Uri.parse(
      'https://github.com/owner/repo/releases/download/v3.0.3/plugin.zip',
    );
    when(() => network.get(uri)).thenAnswer(
      (_) async => http.Response.bytes(metadataBytes, 200),
    );

    expect(await catalog.download(manifest), metadataBytes);
  });

  test('download throws for a manifest the catalog does not know', () {
    final unknown = PluginManifest(
      id: 'org.unknown',
      packageId: 'unknown',
      type: 'metadata',
      name: 'Unknown',
      version: '9.9.9',
      pluginSdkVersion: '1.0.0',
      author: 'Tester',
      description: 'Unknown',
    );

    expect(
      () => catalog.download(unknown),
      throwsA(isA<PluginDownloadException>()),
    );
  });

  test('a failed search surfaces PluginSearchException', () async {
    when(
      () => network.get(Uri.parse(searchUri)),
    ).thenAnswer((_) async => http.Response('rate limited', 403));

    expect(
      () => catalog.latest(PluginType.metadata),
      throwsA(isA<PluginSearchException>()),
    );
  });

  test('a broken repository does not hide the others', () async {
    when(
      () => network.get(Uri.parse(metadataRelease)),
    ).thenAnswer((_) async => http.Response('not found', 404));

    final manifests = await catalog.latest(PluginType.metadata);

    expect(manifests, isEmpty);
    final audio = await catalog.latest(PluginType.audioSource);
    expect(audio.keys, ['org.musicare.audiosource.test']);
  });
}
