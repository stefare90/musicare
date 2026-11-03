import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/notice/error_presentation.dart';
import 'package:music_are/core/notice/system_error_table.dart';
import 'package:music_are/features/player/presentation/audio_error_table.dart';
import 'package:music_are/features/plugin/metadata/presentation/metadata_error_table.dart';
import 'package:music_are/features/plugin/shared/presentation/plugin_error_table.dart';
import 'package:music_are/features/plugin/shared/presentation/runtime_error_table.dart';

const testErrorPresentation = ErrorPresentation([
  MetadataErrorTable(),
  AudioErrorTable(),
  RuntimeErrorTable(),
  SystemErrorTable(),
  PluginErrorTable(),
]);

/// Idempotent: tests that already reset `sl` can call it on every `setUp`.
void registerTestErrorPresentation() {
  if (!sl.isRegistered<ErrorPresentation>()) {
    sl.registerLazySingleton<ErrorPresentation>(() => testErrorPresentation);
  }
}
