import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_runtime_boot.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_storage.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLauncher implements PythonLauncher {
  _FakeLauncher({this.failures = 0, this.events});

  final int failures;
  final List<String>? events;
  int calls = 0;

  @override
  Future<void> run(Map<String, String> environmentVariables) async {
    calls++;
    events?.add('boot');
    if (calls <= failures) throw StateError('launcher failed');
  }

  @override
  void terminate() {}
}

class _MockStorage extends Mock implements PluginStorage {}

MockClient _healthyRuntime() =>
    MockClient((_) async => http.Response('{"status":"ok"}', 200));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PreferencesService preferences;
  late PluginStorage storage;

  setUpAll(() {
    registerFallbackValue(<String>{});
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('plugin_runtime_boot_test_');
    SharedPreferences.setMockInitialValues({});
    preferences = PreferencesService(await SharedPreferences.getInstance());
    storage = PluginStorage(appDir: () async => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  RuntimeHost hostWith(_FakeLauncher launcher) => RuntimeHost(
    launcher: launcher,
    httpClient: _healthyRuntime(),
    bootTimeout: const Duration(milliseconds: 500),
    pingInterval: const Duration(milliseconds: 5),
  );

  PluginRuntimeBoot bootWith(_FakeLauncher launcher, {PluginStorage? store}) =>
      PluginRuntimeBoot(
        host: hostWith(launcher),
        preferences: preferences,
        storage: store ?? storage,
        processId: () => 42,
      );

  Directory version(String id, String versionDir) {
    final dir = Directory(
      '${tempDir.path}/plugins/metadata/$id/$versionDir',
    )..createSync(recursive: true);
    File('${dir.path}/plugin.json').writeAsStringSync(
      jsonEncode({
        'id': id,
        'packageId': '${id}_package',
        'type': 'metadata',
        'name': 'Plugin',
        'version': '1.0.0',
        'pluginSdkVersion': '6.0.0',
        'author': 'Tester',
        'description': 'Test',
      }),
    );
    return dir;
  }

  test('attaches to the runtime this process is already serving', () async {
    final first = await bootWith(_FakeLauncher()).start();

    final secondLauncher = _FakeLauncher();
    final probed = <int>[];
    final second = await PluginRuntimeBoot(
      host: hostWith(secondLauncher),
      preferences: preferences,
      storage: storage,
      processId: () => 42,
      ping: (port) async {
        probed.add(port);
        return true;
      },
    ).start();

    expect(secondLauncher.calls, 0, reason: 'the interpreter is not booted again');
    expect(probed.toSet(), {
      first.portOf(Subsystem.audio),
      first.portOf(Subsystem.metadata),
    });
    expect(second.portOf(Subsystem.audio), first.portOf(Subsystem.audio));
    expect(second.portOf(Subsystem.metadata), first.portOf(Subsystem.metadata));
  });

  test('ignores a session written by another process', () async {
    await bootWith(_FakeLauncher()).start();

    final launcher = _FakeLauncher();
    var probed = false;
    await PluginRuntimeBoot(
      host: hostWith(launcher),
      preferences: preferences,
      storage: storage,
      processId: () => 43,
      ping: (_) async {
        probed = true;
        return true;
      },
    ).start();

    expect(probed, isFalse, reason: 'a dead process ports are not trusted');
    expect(launcher.calls, 1);
  });

  test('boots when the saved ports no longer answer', () async {
    await bootWith(_FakeLauncher()).start();

    final launcher = _FakeLauncher();
    await PluginRuntimeBoot(
      host: hostWith(launcher),
      preferences: preferences,
      storage: storage,
      processId: () => 42,
      ping: (_) async => false,
    ).start();

    expect(launcher.calls, 1);
  });

  test('prepares the store before the interpreter starts', () async {
    final events = <String>[];
    final mocked = _MockStorage();
    when(() => mocked.prune(keep: any(named: 'keep'))).thenAnswer((_) async {
      events.add('prune');
      return const [];
    });

    await bootWith(_FakeLauncher(events: events), store: mocked).start();

    expect(events, ['prune', 'boot']);
  });

  test('prunes the retired versions before booting', () async {
    final retired = version('org.example', 'plugin_version_1.0.0');
    final active = version('org.example', 'plugin_version_2.0.0');
    await preferences.setActivePluginId(PluginType.metadata, 'org.example');
    await preferences.setActivePluginVersionDir(
      PluginType.metadata,
      'plugin_version_2.0.0',
    );

    await bootWith(_FakeLauncher()).start();

    expect(active.existsSync(), isTrue);
    expect(retired.existsSync(), isFalse);
  });

  test('does not touch the store when it attaches to a live runtime', () async {
    await bootWith(_FakeLauncher()).start();
    final previous = version('org.example', 'plugin_version_1.0.0');

    await PluginRuntimeBoot(
      host: hostWith(_FakeLauncher()),
      preferences: preferences,
      storage: storage,
      processId: () => 42,
      ping: (_) async => true,
    ).start();

    expect(
      previous.existsSync(),
      isTrue,
      reason: 'a live interpreter may still read the store',
    );
  });

  test('a second start after a failed boot retries instead of staying started', () async {
    final launcher = _FakeLauncher(failures: 1);
    final boot = bootWith(launcher);

    await expectLater(boot.start(), throwsA(isA<StateError>()));
    expect(launcher.calls, 1);
    expect(
      preferences.getRuntimeSession(),
      isNull,
      reason: 'a failed boot must not be remembered as a runtime',
    );

    final ports = await boot.start();

    expect(launcher.calls, 2, reason: 'the failure left no stale started flag');
    expect(ports.portOf(Subsystem.audio), greaterThan(0));
    expect(preferences.getRuntimeSession(), isNotNull);
  });

  test('an unreadable session is ignored, not fatal', () async {
    await preferences.setRuntimeSession('not json');

    final launcher = _FakeLauncher();
    final ports = await bootWith(launcher).start();

    expect(launcher.calls, 1);
    expect(ports.portOf(Subsystem.metadata), greaterThan(0));
  });
}
