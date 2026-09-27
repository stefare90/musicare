import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/sign_in_card.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/utils/plugin_status_card.dart';

import '../../../../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  Widget buildTestableWidget(
    Object error, {
    VoidCallback? onRetry,
    MetadataPluginCubit? cubit,
  }) {
    return BlocProvider<MetadataPluginCubit>.value(
      value: cubit ?? buildMockMetadataPluginCubit(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                Center(child: error.toStatusCard(context, onRetry: onRetry)),
          ),
        ),
      ),
    );
  }

  testWidgets('auth_required presents a SignInCard', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(const MetadataAuthRequiredException('sign in')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInCard), findsOneWidget);
    expect(find.byType(ErrorCard), findsNothing);
  });

  testWidgets('any other error presents an ErrorCard and forwards onRetry', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      buildTestableWidget(Exception('boom'), onRetry: () => retried = true),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorCard), findsOneWidget);
    expect(find.byType(SignInCard), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);
  });
}
