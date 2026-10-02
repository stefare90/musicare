import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';

extension ExceptionLocalizer on Object {
  String toLocalizedString(BuildContext context) {
    return switch (this) {
      // Plugin Audio Source
      StreamResolutionException() => context.l10n.pluginErrorStreamResolution,
      RuntimeBootTimeoutException() => context.l10n.pluginErrorTimeout,

      // Plugin Shared
      IncompatibleSdkVersionException() =>
        context.l10n.pluginErrorIncompatibleSdkVersion,
      PluginNotLoadedException() => context.l10n.pluginErrorNotLoaded,
      PluginFileNotFoundException() => context.l10n.pluginErrorNotFound,
      InvalidPluginArchiveException() => context.l10n.pluginErrorInvalidArchive,
      InvalidPluginTypeException() => context.l10n.pluginErrorInvalidArchive,
      PluginDownloadException() => context.l10n.pluginErrorDownloadFailed,
      PluginSearchException() => context.l10n.pluginErrorNetwork,

      // UI Service
      PluginErrorNoContext() => context.l10n.pluginErrorNoContext,

      // Metadata SDK
      MetadataAuthRequiredException() => context.l10n.pluginErrorAuthRequired,
      MetadataTransportException() => context.l10n.pluginErrorNetwork,
      MetadataRateLimitedException() => context.l10n.pluginErrorRateLimited,

      // Generics & System (Network, Timeout, Fallbacks)
      SocketException() => context.l10n.pluginErrorNetwork,
      TimeoutException() => context.l10n.pluginErrorTimeout,
      _ => context.l10n.pluginErrorUnknown(
        toString().replaceAll('Exception: ', ''),
      ),
    };
  }
}
