import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/data/exceptions/plugin_engine_exceptions.dart';

/// Extension mapping custom, system, or third-party exceptions to localized L10n strings
extension ExceptionLocalizer on Object {
  String toLocalizedString(BuildContext context) {
    return switch (this) {
      // Custom Domain Exceptions
      IncompatibleSdkVersionException() =>
        context.l10n.pluginErrorIncompatibleSdkVersion,
      InvalidPluginArchiveException() => context.l10n.pluginErrorInvalidArchive,
      PluginFileNotFoundException() => context.l10n.pluginErrorNotFound,
      PluginNotLoadedException() => context.l10n.pluginErrorNotLoaded,
      PluginDownloadException() => context.l10n.pluginErrorDownloadFailed,
      PluginSearchException() => context.l10n.pluginErrorNetwork,
      NavigationContextUnavailableException() =>
        context.l10n.pluginErrorUnknown('Navigation context unavailable'),

      // System I/O Exceptions
      SocketException() => context.l10n.pluginErrorNetwork,
      TimeoutException() => context.l10n.pluginErrorTimeout,

      // Fallback for unexpected exceptions
      _ => context.l10n.pluginErrorUnknown(
        toString().replaceAll('Exception: ', ''),
      ),
    };
  }
}
