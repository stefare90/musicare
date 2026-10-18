import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/player/presentation/cubit/playback_settings_state.dart';

class PlaybackSettingsCubit extends SafeCubit<PlaybackSettingsState> {
  final PreferencesService _preferences;

  PlaybackSettingsCubit(this._preferences)
    : super(
        PlaybackSettingsState(
          infiniteMusic: _preferences.getInfiniteMusic() ?? true,
        ),
      );

  void setInfiniteMusic(bool value) {
    if (value == state.infiniteMusic) return;
    emit(state.copyWith(infiniteMusic: value));
    _preferences.setInfiniteMusic(value);
  }
}
