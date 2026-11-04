import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/l10n/app_localizations_en.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/metadata/presentation/errors/metadata_error_table.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';

import '../../../../../helpers/plugin_session_cubit_test_helpers.dart';

void main() {
  const table = MetadataErrorTable();
  final l10n = AppLocalizationsEn();

  const variants = [
    MetadataAuthRequiredException('sign in'),
    MetadataNotFoundException('missing'),
    MetadataRateLimitedException('slow down'),
    MetadataTransportException('timed out'),
    MetadataInvalidArgumentException('bad argument'),
    MetadataUnsupportedException('unsupported'),
    MetadataInternalException('boom'),
  ];

  test('every protocol variant has a non-empty text', () {
    for (final error in variants) {
      final spec = table.describe(error, l10n);
      expect(spec, isNotNull, reason: '$error');
      expect(spec!.text, isNotEmpty, reason: '$error');
    }
  });

  test('keeps the provider detail for transport errors', () {
    final spec = table.describe(
      const MetadataTransportException('Call "user.saved" timed out'),
      l10n,
    );

    expect(spec!.text, 'Network error occurred: Call "user.saved" timed out');
  });

  test('responds null to errors from another domain', () {
    expect(
      table.describe(const AudioNotFoundException('missing'), l10n),
      isNull,
    );
    expect(
      table.describe(const RuntimeNotStartedException('down'), l10n),
      isNull,
    );
    expect(table.describe(Exception('boom'), l10n), isNull);
  });

  test('only auth-required is notifiable and offers the sign-in action', () {
    final auth = table.describe(
      const MetadataAuthRequiredException('sign in'),
      l10n,
    );
    final missing = table.describe(const MetadataNotFoundException('x'), l10n);

    expect(auth!.action, isNotNull);
    expect(missing!.action, isNull);
    expect(
      table.notifies(const MetadataAuthRequiredException('sign in')),
      isTrue,
    );
    expect(table.notifies(const MetadataNotFoundException('x')), isFalse);
  });

  testWidgets('the sign-in action opens the metadata login', (tester) async {
    late BuildContext context;
    var signInCalls = 0;
    final plugins = buildTestPluginSessionCubit()
      ..onSignIn = (_) => signInCalls++;

    await tester.pumpWidget(
      BlocProvider<PluginSessionCubit>.value(
        value: plugins,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final spec = table.describe(
      const MetadataAuthRequiredException('sign in'),
      context.l10n,
    )!;
    final action = spec.action!(context);

    expect(action.label, 'Sign in');
    action.onAction();
    await tester.pump();

    expect(signInCalls, 1);
  });
}
