enum AudioQuality {
  low,
  medium,
  high;

  String get value => name;

  static AudioQuality fromString(String value) {
    return switch (value.toLowerCase()) {
      'low' => AudioQuality.low,
      'medium' => AudioQuality.medium,
      'high' => AudioQuality.high,
      _ => AudioQuality.high,
    };
  }
}
