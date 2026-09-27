import 'package:flutter/widgets.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

extension PluginTypeLocalizer on PluginType {
  String toLocalizedString(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      PluginType.metadata => l10n.pluginTypeMetadata,
      PluginType.audioSource => l10n.pluginTypeAudioSource,
    };
  }
}
