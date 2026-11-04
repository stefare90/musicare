import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/presentation/errors/app_update_error_table.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  const table = UpdateErrorTable();

  test('maps rate-limited and generic check failures to their messages', () {
    expect(
      table.describe(const UpdateCheckFailed(statusCode: 403), l10n)!.text,
      l10n.updateErrorRateLimited,
    );
    expect(
      table.describe(const UpdateCheckFailed(statusCode: 429), l10n)!.text,
      l10n.updateErrorRateLimited,
    );
    expect(
      table.describe(const UpdateCheckFailed(statusCode: 500), l10n)!.text,
      l10n.updateErrorCheck,
    );
    expect(
      table.describe(const UpdateCheckFailed(), l10n)!.text,
      l10n.updateErrorCheck,
    );
  });
}
