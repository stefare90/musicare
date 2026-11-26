import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_auth_controller.dart';
import 'package:musicare_auth_host_sdk/musicare_auth_host_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Unsupported implements Exception {}

class FakeAuthFlow implements IAuth {
  AuthStatus statusValue = const AuthStatus(authenticated: false);
  AuthStatus authenticated = const AuthStatus(authenticated: false);
  Object? statusError;
  Object? authenticateError;
  Object? logoutError;
  int logouts = 0;

  @override
  Future<AuthStatus> authenticate() async {
    if (authenticateError != null) throw authenticateError!;
    return authenticated;
  }

  @override
  Future<bool> isAuthenticated() async => (await status()).authenticated;

  @override
  Future<AuthStatus> status() async {
    if (statusError != null) throw statusError!;
    return statusValue;
  }

  @override
  Future<void> logout() async {
    logouts++;
    if (logoutError != null) throw logoutError!;
  }
}

void main() {
  const pluginId = 'org.test.plugin';

  late FakeAuthFlow flow;
  late PreferencesService preferences;
  late bool available;
  late String? activeId;
  late PluginAuthController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    flow = FakeAuthFlow();
    preferences = PreferencesService(await SharedPreferences.getInstance());
    available = true;
    activeId = pluginId;
    controller = PluginAuthController(
      available: () => available,
      activePluginId: () => activeId,
      flow: flow,
      preferences: preferences,
      isUnsupported: (error) => error is Unsupported,
    );
  });

  test('refresh is unavailable when the plugin is not loaded', () async {
    available = false;

    await controller.refresh();

    expect(controller.authState.status, PluginAuthStatus.unavailable);
  });

  test('refresh maps an unsupported auth surface to unavailable', () async {
    flow.statusError = Unsupported();

    await controller.refresh();

    expect(controller.authState.status, PluginAuthStatus.unavailable);
    expect(controller.authState.error, isNull);
  });

  test('refresh reports signed out and clears the cached account', () async {
    await preferences.setPluginAccount(pluginId, id: 'old', name: 'Old');

    await controller.refresh();

    expect(controller.authState.status, PluginAuthStatus.signedOut);
    expect(preferences.pluginAccount(pluginId), isNull);
    expect(controller.cachedAccount, isNull);
  });

  test('refresh reports the account and caches it', () async {
    flow.statusValue = const AuthStatus(
      authenticated: true,
      account: Account(id: 'listener', displayName: 'Listener'),
    );

    await controller.refresh();

    expect(controller.authState.status, PluginAuthStatus.signedIn);
    expect(controller.authState.account?.id, 'listener');
    expect(controller.authState.account?.displayName, 'Listener');
    expect(
      preferences.pluginAccount(pluginId),
      (id: 'listener', name: 'Listener'),
    );
  });

  test('refresh accepts an authenticated plugin with no account', () async {
    flow.statusValue = const AuthStatus(authenticated: true);

    await controller.refresh();

    expect(controller.authState.status, PluginAuthStatus.signedIn);
    expect(controller.authState.isAuthenticated, isTrue);
    expect(controller.authState.account, isNull);
    expect(controller.authState.displayName, isNull);
  });

  test('refresh keeps the cached account when the plugin reports none', () async {
    await preferences.setPluginAccount(pluginId, id: 'cached', name: 'Cached');
    flow.statusValue = const AuthStatus(authenticated: true);

    await controller.refresh();

    expect(controller.authState.account?.id, 'cached');
    expect(controller.authState.displayName, 'Cached');
  });

  test('refresh reports a failure', () async {
    flow.statusError = Exception('offline');

    await controller.refresh();

    expect(controller.authState.status, PluginAuthStatus.error);
    expect(controller.authState.error, isA<Exception>());
  });

  test('refresh ignores an answer that belongs to the previous plugin', () async {
    final completer = Completer<AuthStatus>();
    final slow = _SlowFlow(completer.future);
    controller = PluginAuthController(
      available: () => available,
      activePluginId: () => activeId,
      flow: slow,
      preferences: preferences,
      isUnsupported: (error) => error is Unsupported,
    );

    final pending = controller.refresh();
    activeId = 'org.test.other';
    completer.complete(
      const AuthStatus(authenticated: true, account: Account(id: 'stale')),
    );
    await pending;

    expect(controller.authState.status, PluginAuthStatus.unavailable);
  });

  test('authenticate reports the account and caches it', () async {
    flow.authenticated = const AuthStatus(
      authenticated: true,
      account: Account(id: 'listener', displayName: 'Listener'),
    );

    await controller.authenticate();

    expect(controller.authState.status, PluginAuthStatus.signedIn);
    expect(controller.authState.account?.id, 'listener');
    expect(
      preferences.pluginAccount(pluginId),
      (id: 'listener', name: 'Listener'),
    );
  });

  test('a cancelled form leaves the plugin signed out', () async {
    flow.authenticated = const AuthStatus(authenticated: false);

    await controller.authenticate();

    expect(controller.authState.status, PluginAuthStatus.signedOut);
  });

  test('a failed sign-in is reported and rethrown', () async {
    flow.authenticateError = Exception('bad token');

    await expectLater(controller.authenticate(), throwsA(isA<Exception>()));

    expect(controller.authState.status, PluginAuthStatus.error);
  });

  test('authenticate throws when the plugin is not loaded', () async {
    available = false;

    await expectLater(
      controller.authenticate(),
      throwsA(isA<PluginNotLoadedException>()),
    );
  });

  test('logout clears the account and signs out', () async {
    await preferences.setPluginAccount(pluginId, id: 'listener');
    flow.statusValue = const AuthStatus(
      authenticated: true,
      account: Account(id: 'listener'),
    );
    await controller.refresh();

    await controller.logout();

    expect(flow.logouts, 1);
    expect(controller.authState.status, PluginAuthStatus.signedOut);
    expect(preferences.pluginAccount(pluginId), isNull);
  });

  test('logout still clears the account when the plugin fails', () async {
    await preferences.setPluginAccount(pluginId, id: 'listener');
    flow.logoutError = Exception('offline');

    await expectLater(controller.logout(), throwsA(isA<Exception>()));

    expect(controller.authState.status, PluginAuthStatus.signedOut);
    expect(preferences.pluginAccount(pluginId), isNull);
  });

  test('signing out without a loaded plugin only emits the state', () async {
    available = false;

    await controller.logout();

    expect(flow.logouts, 0);
    expect(controller.authState.status, PluginAuthStatus.signedOut);
  });

  test('isAuthenticated reads the status without starting a flow', () async {
    flow.statusValue = const AuthStatus(authenticated: true);

    expect(await controller.isAuthenticated(), isTrue);
  });

  test('isAuthenticated is false when the auth surface is unsupported', () async {
    flow.statusError = Unsupported();

    expect(await controller.isAuthenticated(), isFalse);
  });

  test('cachedAccount reads the persisted id and name', () async {
    await preferences.setPluginAccount(pluginId, id: 'listener', name: 'L');

    expect(controller.cachedAccount?.id, 'listener');
    expect(controller.cachedAccount?.displayName, 'L');
  });
}

class _SlowFlow implements IAuth {
  _SlowFlow(this.response);

  final Future<AuthStatus> response;

  @override
  Future<AuthStatus> status() => response;

  @override
  Future<bool> isAuthenticated() async => (await response).authenticated;

  @override
  Future<AuthStatus> authenticate() => response;

  @override
  Future<void> logout() async {}
}
