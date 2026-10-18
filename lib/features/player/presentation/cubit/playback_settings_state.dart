class PlaybackSettingsState {
  final bool infiniteMusic;

  const PlaybackSettingsState({required this.infiniteMusic});

  PlaybackSettingsState copyWith({bool? infiniteMusic}) {
    return PlaybackSettingsState(
      infiniteMusic: infiniteMusic ?? this.infiniteMusic,
    );
  }
}
