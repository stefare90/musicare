import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/errors/app_error_presentation.dart';
import 'package:music_are/core/errors/error_presentation.dart';

const ErrorPresentation testErrorPresentation = appErrorPresentation;

/// Idempotent: tests that already reset `sl` can call it on every `setUp`.
void registerTestErrorPresentation() {
  if (!sl.isRegistered<ErrorPresentation>()) {
    sl.registerLazySingleton<ErrorPresentation>(() => testErrorPresentation);
  }
}
