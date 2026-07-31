abstract class PluginException implements Exception {}

class PluginNotLoadedException extends PluginException {}

class PluginFileNotFoundException extends PluginException {
  final String pluginId;
  PluginFileNotFoundException(this.pluginId);
}

class InvalidPluginArchiveException extends PluginException {}

class IncompatibleSdkVersionException extends PluginException {
  final String pluginVersion;
  final String hostVersion;

  IncompatibleSdkVersionException({
    required this.pluginVersion,
    required this.hostVersion,
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

class NavigationContextUnavailableException extends PluginException {}
