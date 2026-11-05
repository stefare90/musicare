import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/router/app_routes.dart';
import 'package:music_are/core/services/plugin_startup_route.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';

import '../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  final manifest = testPluginManifest();
  final loaded = PluginLifecycleState.loaded(manifest);
  final incompatible = PluginLifecycleState.incompatible(manifest);
  const notConfigured = PluginLifecycleState.notConfigured();

  test('both loaded plugins start on Home', () {
    expect(
      pluginStartupLocation(metadataState: loaded, audioState: loaded),
      AppRoutes.home,
    );
  });

  test('no installed plugin starts onboarding', () {
    expect(
      pluginStartupLocation(
        metadataState: notConfigured,
        audioState: notConfigured,
      ),
      AppRoutes.welcome,
    );
  });

  test('a loaded metadata plugin with a missing audio plugin opens setup', () {
    expect(
      pluginStartupLocation(metadataState: loaded, audioState: notConfigured),
      AppRoutes.pluginSetup,
    );
  });

  test('an incompatible metadata plugin opens setup', () {
    expect(
      pluginStartupLocation(metadataState: incompatible, audioState: loaded),
      AppRoutes.pluginSetup,
    );
  });

  test('an incompatible audio plugin opens setup', () {
    expect(
      pluginStartupLocation(metadataState: loaded, audioState: incompatible),
      AppRoutes.pluginSetup,
    );
  });

  test('two incompatible plugins open setup once', () {
    expect(
      pluginStartupLocation(
        metadataState: incompatible,
        audioState: incompatible,
      ),
      AppRoutes.pluginSetup,
    );
  });
}
