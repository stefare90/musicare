import 'package:music_are/core/router/app_routes.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

String pluginStartupLocation({
  required PluginLifecycleState metadataState,
  required PluginLifecycleState audioState,
}) {
  if (metadataState.status == PluginLifecycleStatus.incompatible) {
    return '${AppRoutes.pluginUpdate}/${PluginType.metadata.name}';
  }
  if (audioState.status == PluginLifecycleStatus.incompatible) {
    return '${AppRoutes.pluginUpdate}/${PluginType.audioSource.name}';
  }
  if (metadataState.isLoaded && audioState.isLoaded) {
    return '/';
  }
  return '/welcome';
}
