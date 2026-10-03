import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/settings/presentation/pages/plugin_detail_page.dart';

import '../../../../helpers/audio_source_test_helpers.dart';
import '../../../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  Widget buildTestableWidget({
    required PluginType type,
    MetadataPluginCubit? metadataCubit,
    AudioSourcePluginCubit? audioCubit,
    AccountCubit? authCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MetadataPluginCubit>.value(
          value: metadataCubit ?? buildMockMetadataPluginCubit(),
        ),
        BlocProvider<AudioSourcePluginCubit>.value(
          value: audioCubit ?? buildMockAudioSourcePluginCubit(),
        ),
        BlocProvider<AccountCubit>.value(
          value: authCubit ?? buildMockAccountCubit(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PluginDetailPage(type: type),
      ),
    );
  }

  testWidgets('metadata detail shows version and the signed-in account', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        type: PluginType.metadata,
        authCubit: buildMockAccountCubit(
          state: testAccountState(isAuthenticated: true, userId: 'listener'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Provider'), findsOneWidget);
    expect(find.text('Installed version'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.text('Plugin SDK'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('listener'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('metadata detail signs in when signed out', (tester) async {
    var signInCalls = 0;
    await tester.pumpWidget(
      buildTestableWidget(
        type: PluginType.metadata,
        authCubit: buildMockAccountCubit(
          onSignIn: () async {
            signInCalls++;
            return AuthResult.authenticated;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not signed in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(signInCalls, 1);
  });

  testWidgets('audio source detail shows the version without an account', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(type: PluginType.audioSource));
    await tester.pumpAndSettle();

    expect(find.text('Test Audio'), findsOneWidget);
    expect(find.text('Installed version'), findsOneWidget);
    expect(find.text('Account'), findsNothing);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('shows the empty state when the plugin is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        type: PluginType.metadata,
        metadataCubit: buildMockMetadataPluginCubit(
          state: MetadataPluginNotConfiguredState(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not configured'), findsOneWidget);
  });
}
