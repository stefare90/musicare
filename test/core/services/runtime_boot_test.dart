import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/core/services/runtime_boot.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLauncher implements PythonLauncher {
  _FakeLauncher({this.failures = 0});

  final int failures;
  int calls = 0;

  @override
  Future<void> run(Map<String, String> environmentVariables) async {
    calls++;
    if (calls <= failures) throw StateError('launcher failed');
  }

  @override
  void terminate() {}
}

MockClient _healthyRuntime() =>
    MockClient((_) async => http.Response('{"status":"ok"}', 200));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = PreferencesService(await SharedPreferences.getInstance());
  });

  RuntimeHost hostWith(_FakeLauncher launcher) => RuntimeHost(
    launcher: launcher,
    httpClient: _healthyRuntime(),
    bootTimeout: const Duration(milliseconds: 500),
    pingInterval: const Duration(milliseconds: 5),
  );

  test('attaches to the runtime this process is already serving', () async {
    final firstLauncher = _FakeLauncher();
    final first = await RuntimeBoot(
      host: hostWith(firstLauncher),
      preferences: preferences,
      processId: () => 42,
    ).start();

    final secondLauncher = _FakeLauncher();
    final probed = <int>[];
    final second = await RuntimeBoot(
      host: hostWith(secondLauncher),
      preferences: preferences,
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
    await RuntimeBoot(
      host: hostWith(_FakeLauncher()),
      preferences: preferences,
      processId: () => 42,
    ).start();

    final launcher = _FakeLauncher();
    var probed = false;
    await RuntimeBoot(
      host: hostWith(launcher),
      preferences: preferences,
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
    await RuntimeBoot(
      host: hostWith(_FakeLauncher()),
      preferences: preferences,
      processId: () => 42,
    ).start();

    final launcher = _FakeLauncher();
    await RuntimeBoot(
      host: hostWith(launcher),
      preferences: preferences,
      processId: () => 42,
      ping: (_) async => false,
    ).start();

    expect(launcher.calls, 1);
  });

  test('a second start after a failed boot retries instead of staying started', () async {
    final launcher = _FakeLauncher(failures: 1);
    final boot = RuntimeBoot(
      host: hostWith(launcher),
      preferences: preferences,
      processId: () => 42,
    );

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
    final ports = await RuntimeBoot(
      host: hostWith(launcher),
      preferences: preferences,
      processId: () => 42,
    ).start();

    expect(launcher.calls, 1);
    expect(ports.portOf(Subsystem.metadata), greaterThan(0));
  });
}
