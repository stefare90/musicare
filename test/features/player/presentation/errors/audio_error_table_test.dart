import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations_en.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/player/presentation/errors/audio_error_table.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/cubit/plugin_session_cubit.dart';

import '../../../../helpers/plugin_session_cubit_test_helpers.dart';

class MockPlayerCubit extends Mock implements PlayerCubit {}

void main() {
  const table = AudioErrorTable();
  final l10n = AppLocalizationsEn();

  const variants = [
    AudioAuthRequiredException('sign in'),
    AudioNotFoundException('missing'),
    AudioRateLimitedException('slow down'),
    AudioTransportException('timed out'),
    AudioInvalidArgumentException('bad argument'),
    AudioUnsupportedException('unsupported'),
    AudioInternalException('boom'),
  ];

  test('every protocol variant has a non-empty text', () {
    for (final error in variants) {
      final spec = table.describe(error, l10n);
      expect(spec, isNotNull, reason: '$error');
      expect(spec!.text, isNotEmpty, reason: '$error');
    }
  });

  test('keeps the provider detail for transport and internal errors', () {
    expect(
      table.describe(const AudioTransportException('offline'), l10n)!.text,
      'Network error occurred: offline',
    );
    expect(
      table.describe(const AudioInternalException('no stream'), l10n)!.text,
      'The plugin hit an internal error: no stream',
    );
  });

  test('responds null to errors from another domain', () {
    expect(table.describe(const MetadataNotFoundException('x'), l10n), isNull);
    expect(
      table.describe(const RuntimeNotStartedException('down'), l10n),
      isNull,
    );
    expect(table.describe(Exception('boom'), l10n), isNull);
  });

  test('keeps the provider cause for auth-required errors', () {
    const cause = 'Sign in to YouTube to play this video';
    final spec = table.describe(const AudioAuthRequiredException(cause), l10n);

    expect(spec!.text, cause);
  });

  test('falls back to the localized text when auth-required has no cause', () {
    final spec = table.describe(const AudioAuthRequiredException(''), l10n);

    expect(spec!.text, 'Sign-in required.');
  });

  test('only auth-required and the pending-load wrapper are notifiable', () {
    final pending = table.describe(
      PendingLoadException(Exception('down')),
      l10n,
    );
    final missing = table.describe(const AudioNotFoundException('x'), l10n);

    expect(pending!.action, isNotNull);
    expect(missing!.action, isNull);
    expect(table.notifies(PendingLoadException(Exception('down'))), isTrue);
    expect(table.notifies(const AudioAuthRequiredException('x')), isTrue);
    expect(table.notifies(const AudioNotFoundException('x')), isFalse);
  });

  testWidgets('the auth action opens the audio login', (tester) async {
    late BuildContext context;
    final signedIn = <String>[];
    final plugins = buildTestPluginSessionCubit(
      authStates: const {},
    )..onSignIn = (type) => signedIn.add(type.name);

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
      const AudioAuthRequiredException('sign in'),
      context.l10n,
    )!;
    final action = spec.action!(context);

    expect(action.label, 'Sign in');
    action.onAction();
    await tester.pump();

    expect(signedIn, ['audioSource']);
  });

  testWidgets('the retry action asks the player to reload', (tester) async {
    late BuildContext context;
    final playerCubit = MockPlayerCubit();
    when(() => playerCubit.retryPendingLoad()).thenAnswer((_) async {});
    when(
      () => playerCubit.stream,
    ).thenAnswer((_) => const Stream<PlayerState>.empty());

    await tester.pumpWidget(
      BlocProvider<PlayerCubit>.value(
        value: playerCubit,
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
      PendingLoadException(Exception('down')),
      context.l10n,
    )!;
    final action = spec.action!(context);

    expect(action.label, 'Retry');
    action.onAction();
    await tester.pump();

    verify(() => playerCubit.retryPendingLoad()).called(1);
  });
}
