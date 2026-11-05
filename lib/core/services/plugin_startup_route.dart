import 'package:music_are/core/router/app_routes.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';

String pluginStartupLocation({
  required PluginLifecycleState metadataState,
  required PluginLifecycleState audioState,
}) {
  if (metadataState.isLoaded && audioState.isLoaded) {
    return AppRoutes.home;
  }
  final nothingInstalled =
      metadataState.manifest == null && audioState.manifest == null;
  if (nothingInstalled) {
    return AppRoutes.welcome;
  }
  return AppRoutes.pluginSetup;
}
