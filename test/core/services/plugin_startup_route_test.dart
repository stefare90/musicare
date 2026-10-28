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

  test('an incompatible metadata plugin takes priority', () {
    expect(
      pluginStartupLocation(metadataState: incompatible, audioState: loaded),
      '${AppRoutes.pluginUpdate}/metadata',
    );
  });

  test('an incompatible audio plugin opens its own update page', () {
    expect(
      pluginStartupLocation(metadataState: loaded, audioState: incompatible),
      '${AppRoutes.pluginUpdate}/audioSource',
    );
  });

  test('metadata wins when both plugins are incompatible', () {
    expect(
      pluginStartupLocation(
        metadataState: incompatible,
        audioState: incompatible,
      ),
      '${AppRoutes.pluginUpdate}/metadata',
    );
  });

  test('both loaded plugins start on Home', () {
    expect(
      pluginStartupLocation(metadataState: loaded, audioState: loaded),
      '/',
    );
  });

  test('a missing plugin starts onboarding', () {
    expect(
      pluginStartupLocation(metadataState: loaded, audioState: notConfigured),
      '/welcome',
    );
    expect(
      pluginStartupLocation(
        metadataState: notConfigured,
        audioState: notConfigured,
      ),
      '/welcome',
    );
  });
}
