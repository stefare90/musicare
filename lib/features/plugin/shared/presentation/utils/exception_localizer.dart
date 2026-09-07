import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

extension ExceptionLocalizer on Object {
  String toLocalizedString(BuildContext context) {
    return switch (this) {
      IncompatibleSdkVersionException() =>
        context.l10n.pluginErrorIncompatibleSdkVersion,
      InvalidPluginArchiveException() => context.l10n.pluginErrorInvalidArchive,
      InvalidPluginTypeException() => context.l10n.pluginErrorInvalidType,
      AudioSourceDaemonStartupTimeoutException() =>
        context.l10n.pluginErrorTimeout,
      AudioSourceStreamResolutionException(message: final msg) =>
        context.l10n.pluginErrorUnknown(msg),
      PluginFileNotFoundException() => context.l10n.pluginErrorNotFound,
      PluginNotLoadedException() => context.l10n.pluginErrorNotLoaded,
      PluginDownloadException() => context.l10n.pluginErrorDownloadFailed,
      PluginSearchException() => context.l10n.pluginErrorNetwork,
      SocketException() => context.l10n.pluginErrorNetwork,
      TimeoutException() => context.l10n.pluginErrorTimeout,
      PluginErrorNoContext() => context.l10n.pluginErrorNoContext,
      _ => context.l10n.pluginErrorUnknown(
        toString().replaceAll('Exception: ', ''),
      ),
    };
  }
}
