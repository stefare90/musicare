import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

import '../../../../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  late BuildContext context;

  Future<void> pumpContext(
    WidgetTester tester,
    MetadataPluginCubit cubit,
  ) async {
    await tester.pumpWidget(
      BlocProvider<MetadataPluginCubit>.value(
        value: cubit,
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
  }

  testWidgets('auth errors need a notice and offer the sign-in action', (
    tester,
  ) async {
    var authenticateCalls = 0;
    await pumpContext(
      tester,
      buildMockMetadataPluginCubit(
        onAuthenticate: () async {
          authenticateCalls++;
          return AuthResult.authenticated;
        },
      ),
    );

    final error = const MetadataAuthRequiredException('sign in');

    expect(error.needsNotice, isTrue);

    final action = error.noticeAction(context);
    expect(action, isNotNull);
    expect(action!.label, 'Sign in');

    action.onAction();
    await tester.pump();

    expect(authenticateCalls, 1);
  });

  testWidgets('other errors are neither notifiable nor actionable', (
    tester,
  ) async {
    await pumpContext(tester, buildMockMetadataPluginCubit());

    expect(Exception('boom').needsNotice, isFalse);
    expect(Exception('boom').noticeAction(context), isNull);
    expect(const MetadataNotFoundException('missing').needsNotice, isFalse);
    expect(const MetadataNotFoundException('missing').noticeAction(context), isNull);
  });
}
