enum PlaybackRepeatMode {
  off,
  all,
  one;

  PlaybackRepeatMode next() {
    switch (this) {
      case PlaybackRepeatMode.off:
        return PlaybackRepeatMode.all;
      case PlaybackRepeatMode.all:
        return PlaybackRepeatMode.one;
      case PlaybackRepeatMode.one:
        return PlaybackRepeatMode.off;
    }
  }
}
