import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

abstract class PluginException implements Exception {}

class PluginNotLoadedException extends PluginException {}

class PluginFileNotFoundException extends PluginException {
  final String pluginId;
  PluginFileNotFoundException(this.pluginId);
}

class InvalidPluginArchiveException extends PluginException {}

class IncompatibleSdkVersionException extends PluginException {
  final PluginManifest manifest;
  final String hostVersion;

  IncompatibleSdkVersionException({
    required this.manifest,
    required this.hostVersion,
  });
}

class InvalidPluginTypeException extends PluginException {
  final String expectedType;
  final String actualType;

  InvalidPluginTypeException({
    required this.expectedType,
    required this.actualType,
  });
}

class AudioSourceDaemonStartupTimeoutException extends PluginException {
  final int port;
  AudioSourceDaemonStartupTimeoutException(this.port);
}

class AudioSourceStreamResolutionException extends PluginException {
  final int statusCode;
  final String message;

  AudioSourceStreamResolutionException({
    required this.statusCode,
    required this.message,
  });
}

class PluginEntryPointNullException extends PluginException {}

class PluginDownloadException extends PluginException {
  final String? url;
  PluginDownloadException([this.url]);
}

class PluginSearchException extends PluginException {
  final int? statusCode;
  PluginSearchException([this.statusCode]);
}

class PluginErrorNoContext extends PluginException {}
