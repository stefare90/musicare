import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_history_sink.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class MockMetadataPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockListen extends Mock implements IListen {}

class FakeUserSession implements UserSession {
  FakeUserSession({this.isAuthenticated = true});

  @override
  bool isAuthenticated;

  @override
  String? get userId => isAuthenticated ? 'user' : null;

  @override
  Stream<bool> get authenticationChanges => const Stream.empty();
}

PluginManifest manifest(String id) => PluginManifest(
  id: id,
  packageId: '${id}_package',
  type: 'metadata',
  name: id,
  version: '1.0.0',
  pluginSdkVersion: '7.0.0',
  author: 'Tester',
  description: 'Test plugin',
);

Track testTrack() => Track(
  id: 'recording',
  name: 'Karma Police',
  externalUri: '',
  artists: [Artist(id: 'artist', name: 'Radiohead', externalUri: '')],
  album: Album(
    id: 'release-group',
    name: 'OK Computer',
    artists: const [],
    releaseDate: '',
    externalUri: '',
    totalTracks: 12,
    albumType: AlbumType.album,
  ),
  durationMs: 261000,
);

ListenEvent testEvent() => ListenEvent(
  kind: ListenKind.single,
  track: testTrack(),
  listenedAt: DateTime.utc(2026, 11, 9, 12),
);

void main() {
  late MockMetadataPluginEngine engine;
  late MockMetadataPlugin plugin;
  late MockListen listen;
  late FakeUserSession user;
  late MetadataHistorySink sink;

  setUpAll(() => registerFallbackValue(testEvent()));

  setUp(() {
    engine = MockMetadataPluginEngine();
    plugin = MockMetadataPlugin();
    listen = MockListen();
    user = FakeUserSession();
    sink = MetadataHistorySink(engine, user);

    when(() => engine.metadata).thenReturn(plugin);
    when(() => engine.metadataManifest).thenReturn(manifest('plugin.one'));
    when(() => plugin.listen).thenReturn(listen);
    when(() => listen.record(any())).thenAnswer((_) async {});
  });

  test('forwards the event to the active plugin history', () async {
    final event = testEvent();

    await sink.submit(event);

    verify(() => listen.record(event)).called(1);
  });

  test('a signed-out account receives nothing', () async {
    user.isAuthenticated = false;

    await sink.submit(testEvent());

    verifyNever(() => listen.record(any()));
  });

  test('without a loaded plugin there is nobody to call', () async {
    when(() => engine.metadataManifest).thenReturn(null);

    await sink.submit(testEvent());

    verifyNever(() => listen.record(any()));
  });

  test('switches off after an unsupported answer and does not retry', () async {
    when(
      () => listen.record(any()),
    ).thenAnswer((_) async => throw const MetadataUnsupportedException('none'));

    await sink.submit(testEvent());
    await sink.submit(testEvent());
    await sink.submit(testEvent());

    verify(() => listen.record(any())).called(1);
  });

  test('retries once the plugin changes', () async {
    when(
      () => listen.record(any()),
    ).thenAnswer((_) async => throw const MetadataUnsupportedException('none'));
    await sink.submit(testEvent());

    when(
      () => engine.metadataManifest,
    ).thenReturn(manifest('plugin.two'));
    when(() => listen.record(any())).thenAnswer((_) async {});
    await sink.submit(testEvent());

    verify(() => listen.record(any())).called(2);
  });

  test('a transient failure is not remembered', () async {
    when(
      () => listen.record(any()),
    ).thenAnswer((_) async => throw const MetadataTransportException('offline'));
    await sink.submit(testEvent());

    when(() => listen.record(any())).thenAnswer((_) async {});
    await sink.submit(testEvent());

    verify(() => listen.record(any())).called(2);
  });

  test('a failure never escapes the sink', () async {
    when(
      () => listen.record(any()),
    ).thenAnswer((_) async => throw Exception('boom'));

    await expectLater(sink.submit(testEvent()), completes);
  });
}
