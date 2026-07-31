/// Exception thrown when accessing an unloaded plugin
class PluginNotLoadedException implements Exception {
  final String message;
  PluginNotLoadedException([
    this.message = 'No active metadata plugin loaded.',
  ]);

  @override
  String toString() => 'PluginNotLoadedException: $message';
}

class PluginExecutionException implements Exception {
  final String message;
  PluginExecutionException(this.message);

  @override
  String toString() => 'PluginExecutionException: $message';
}
