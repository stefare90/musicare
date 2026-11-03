import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations_en.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

import '../../helpers/error_presentation_test_helpers.dart';

void main() {
  final presentation = testErrorPresentation;
  final l10n = AppLocalizationsEn();

  test('resolves the cause of a rethrown error', () {
    final error = PluginActivationException(
      const MetadataNotFoundException('missing'),
    );

    expect(presentation.text(error, l10n), 'The requested item was not found.');
    expect(presentation.describe(error, l10n)!.action, isNull);
  });

  test('keeps the wrapper action while showing the cause text', () {
    final error = PendingLoadException(Exception('down'));

    expect(
      presentation.text(error, l10n),
      'An unexpected error occurred: down',
    );
    expect(presentation.describe(error, l10n)!.action, isNotNull);
  });

  test('falls back to the generic message for unknown errors', () {
    expect(presentation.describe(Exception('boom'), l10n), isNull);
    expect(
      presentation.text(Exception('boom'), l10n),
      'An unexpected error occurred: boom',
    );
  });

  test('needsNotice comes from the table policies', () {
    expect(
      presentation.needsNotice(const MetadataAuthRequiredException('sign in')),
      isTrue,
    );
    expect(
      presentation.needsNotice(PendingLoadException(Exception('down'))),
      isTrue,
    );
    expect(
      presentation.needsNotice(const MetadataNotFoundException('missing')),
      isFalse,
    );
    expect(presentation.needsNotice(Exception('boom')), isFalse);
  });

  test('the auth action survives composition', () {
    final spec = presentation.describe(
      const MetadataAuthRequiredException('sign in'),
      l10n,
    );

    expect(spec!.text, 'Metadata sign-in required.');
    expect(spec.action, isNotNull);
  });
}
