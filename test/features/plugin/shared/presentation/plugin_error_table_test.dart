import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations_en.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/presentation/plugin_error_table.dart';

void main() {
  const table = PluginErrorTable();
  final l10n = AppLocalizationsEn();

  final manifest = PluginManifest(
    id: 'dummy',
    packageId: 'dummy',
    type: 'metadata',
    name: 'Dummy',
    version: '1.0',
    pluginSdkVersion: '1.0',
    author: 'Author',
    description: 'Desc',
  );

  final variants = <PluginException>[
    PluginNotLoadedException(),
    PluginFileNotFoundException('dummy'),
    InvalidPluginArchiveException(),
    IncompatibleSdkVersionException(manifest: manifest, hostVersion: '9.0'),
    InvalidPluginTypeException(expectedType: 'metadata', actualType: 'audio'),
    PluginActivationException(Exception('boom')),
    PluginDownloadException(),
    PluginSearchException(),
    PluginErrorNoContext(),
    const StreamResolutionException('no stream'),
    const MetadataRadioEmptyException(),
    const PendingLoadException('pending'),
  ];

  test('every plugin variant has a non-empty text', () {
    for (final error in variants) {
      final spec = table.describe(error, l10n);
      expect(spec, isNotNull, reason: '$error');
      expect(spec!.text, isNotEmpty, reason: '$error');
    }
  });

  test('maps the invalid type to its own message', () {
    expect(
      table
          .describe(
            InvalidPluginTypeException(
              expectedType: 'metadata',
              actualType: 'audio',
            ),
            l10n,
          )!
          .text,
      'Plugin type is invalid.',
    );
  });

  test('responds null to errors from another domain', () {
    expect(
      table.describe(const MetadataAuthRequiredException('x'), l10n),
      isNull,
    );
    expect(table.describe(const AudioNotFoundException('x'), l10n), isNull);
    expect(table.describe(Exception('boom'), l10n), isNull);
  });

  test('plugin errors never notify on their own', () {
    for (final error in variants) {
      expect(table.notifies(error), isFalse);
    }
  });
}
