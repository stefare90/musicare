import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:music_are/core/l10n/app_localizations_en.dart';
import 'package:music_are/features/plugin/shared/presentation/runtime_error_table.dart';

void main() {
  const table = RuntimeErrorTable();
  final l10n = AppLocalizationsEn();

  const variants = [
    RuntimeNotStartedException('metadata is not running'),
    RuntimeBootTimeoutException('no ping'),
    PluginInstallException('bad zip'),
  ];

  test('every runtime variant has a non-empty text', () {
    for (final error in variants) {
      final spec = table.describe(error, l10n);
      expect(spec, isNotNull, reason: '$error');
      expect(spec!.text, isNotEmpty, reason: '$error');
    }
  });

  test('keeps the install detail', () {
    expect(
      table.describe(const PluginInstallException('bad zip'), l10n)!.text,
      'The plugin could not be installed: bad zip',
    );
  });

  test('responds null to errors from another domain', () {
    expect(table.describe(const MetadataNotFoundException('x'), l10n), isNull);
    expect(table.describe(const AudioNotFoundException('x'), l10n), isNull);
    expect(table.describe(Exception('boom'), l10n), isNull);
  });

  test('runtime errors are never notifiable on their own', () {
    for (final error in variants) {
      expect(table.notifies(error), isFalse);
    }
  });
}
