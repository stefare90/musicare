import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/errors/error_presentation.dart';
import 'package:music_are/core/errors/exception_localizer.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

import '../../helpers/error_presentation_test_helpers.dart';

void main() {
  setUp(() {
    sl.registerLazySingleton<ErrorPresentation>(() => testErrorPresentation);
  });

  tearDown(() async {
    await sl.reset();
  });

  group('ExceptionLocalizer Unit Tests', () {
    testWidgets('maps domain and system exceptions to localized strings', (
      tester,
    ) async {
      late BuildContext buildContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              buildContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final dummyManifest = PluginManifest(
        id: 'dummy',
        packageId: 'dummy',
        type: 'metadata',
        name: 'Dummy',
        version: '1.0',
        pluginSdkVersion: '1.0',
        author: 'Author',
        description: 'Desc',
      );

      expect(
        const StreamResolutionException(
          'No stream available',
        ).toLocalizedString(buildContext),
        equals('No playable audio stream could be found for this track.'),
      );

      expect(
        IncompatibleSdkVersionException(
          manifest: dummyManifest,
          hostVersion: '1.0.0',
        ).toLocalizedString(buildContext),
        equals('The plugin is incompatible with this version of MusicAre.'),
      );

      expect(
        InvalidPluginArchiveException().toLocalizedString(buildContext),
        equals('The plugin archive is corrupt or missing required files.'),
      );

      expect(
        PluginFileNotFoundException('test_id').toLocalizedString(buildContext),
        equals('Plugin files were not found on local disk.'),
      );

      expect(
        PluginNotLoadedException().toLocalizedString(buildContext),
        equals('No active metadata plugin is loaded.'),
      );

      expect(
        PluginDownloadException().toLocalizedString(buildContext),
        equals('Failed to download the plugin file.'),
      );

      expect(
        PluginSearchException().toLocalizedString(buildContext),
        equals('Network error occurred'),
      );

      expect(
        PluginErrorNoContext().toLocalizedString(buildContext),
        equals('Navigation context is unavailable.'),
      );

      expect(
        const MetadataAuthRequiredException(
          'sign in',
        ).toLocalizedString(buildContext),
        equals('Metadata sign-in required.'),
      );

      expect(
        MetadataRadioEmptyException().toLocalizedString(buildContext),
        equals('No similar tracks for this song.'),
      );

      expect(
        const SocketException(
          'Failed host lookup',
        ).toLocalizedString(buildContext),
        equals('Network error occurred: Failed host lookup'),
      );

      expect(
        const MetadataTransportException(
          'Call "user.saved_artists" timed out after 30s',
        ).toLocalizedString(buildContext),
        equals(
          'Network error occurred: '
          'Call "user.saved_artists" timed out after 30s',
        ),
      );

      expect(
        TimeoutException('Timed out').toLocalizedString(buildContext),
        equals('Connection timed out. Please try again.'),
      );

      expect(
        const AudioInternalException(
          'no stream',
        ).toLocalizedString(buildContext),
        equals('The plugin hit an internal error: no stream'),
      );

      expect(
        const RuntimeNotStartedException(
          'metadata is not running',
        ).toLocalizedString(buildContext),
        equals('The plugin runtime is not running.'),
      );

      expect(
        InvalidPluginTypeException(
          expectedType: 'metadata',
          actualType: 'audio',
        ).toLocalizedString(buildContext),
        equals('Plugin type is invalid.'),
      );

      expect(
        Exception('Custom unexpected error').toLocalizedString(buildContext),
        equals('An unexpected error occurred: Custom unexpected error'),
      );
    });
  });
}
