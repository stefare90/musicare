import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

abstract class PluginException implements Exception {
  const PluginException();
}

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

class PluginActivationException extends PluginException {
  final Object cause;

  const PluginActivationException(this.cause);
}

class PluginDownloadException extends PluginException {
  final String? url;
  PluginDownloadException([this.url]);
}

class PluginSearchException extends PluginException {
  final int? statusCode;
  PluginSearchException([this.statusCode]);
}

class PluginErrorNoContext extends PluginException {}

class StreamResolutionException extends PluginException {
  final String message;

  const StreamResolutionException(this.message);
}

class MetadataRadioEmptyException extends PluginException {
  const MetadataRadioEmptyException();
}

class PendingLoadException extends PluginException {
  final Object cause;

  const PendingLoadException(this.cause);
}
