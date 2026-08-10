import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/data/exceptions/plugin_engine_exceptions.dart';
import 'package:music_are/features/plugin/presentation/utils/exception_localizer.dart';

void main() {
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
        equals('Network error occurred. Please check your connection.'),
      );

      expect(
        PluginErrorNoContext().toLocalizedString(buildContext),
        equals('Navigation context is unavailable.'),
      );

      expect(
        const SocketException(
          'Failed host lookup',
        ).toLocalizedString(buildContext),
        equals('Network error occurred. Please check your connection.'),
      );

      expect(
        TimeoutException('Timed out').toLocalizedString(buildContext),
        equals('Connection timed out. Please try again.'),
      );

      expect(
        Exception('Custom unexpected error').toLocalizedString(buildContext),
        equals('An unexpected error occurred: Custom unexpected error'),
      );

      expect(
        $String('Dart eval wrapped error').toLocalizedString(buildContext),
        equals('An unexpected error occurred: Dart eval wrapped error'),
      );
    });
  });
}
