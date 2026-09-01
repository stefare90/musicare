enum PluginType {
  metadata,
  audioSource;

  static PluginType? fromString(String value) {
    return switch (value.toLowerCase()) {
      'metadata' => PluginType.metadata,
      'audiosource' || 'audio_source' => PluginType.audioSource,
      _ => null,
    };
  }
}
