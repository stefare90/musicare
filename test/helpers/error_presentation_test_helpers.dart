import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/errors/error_presentation.dart';
import 'package:music_are/core/errors/system_error_table.dart';
import 'package:music_are/features/player/presentation/errors/audio_error_table.dart';
import 'package:music_are/features/plugin/metadata/presentation/errors/metadata_error_table.dart';
import 'package:music_are/features/plugin/shared/presentation/errors/plugin_error_table.dart';
import 'package:music_are/features/plugin/shared/presentation/errors/runtime_error_table.dart';
import 'package:music_are/features/update/presentation/errors/app_update_error_table.dart';

const testErrorPresentation = ErrorPresentation([
  MetadataErrorTable(),
  AudioErrorTable(),
  RuntimeErrorTable(),
  SystemErrorTable(),
  PluginErrorTable(),
  UpdateErrorTable(),
]);

/// Idempotent: tests that already reset `sl` can call it on every `setUp`.
void registerTestErrorPresentation() {
  if (!sl.isRegistered<ErrorPresentation>()) {
    sl.registerLazySingleton<ErrorPresentation>(() => testErrorPresentation);
  }
}
