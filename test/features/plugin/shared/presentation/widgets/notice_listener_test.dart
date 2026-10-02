import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/notice_listener.dart';

import '../../../../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  late StreamController<Object> controller;

  setUp(() {
    controller = StreamController<Object>.broadcast();
  });

  tearDown(() async {
    await controller.close();
  });

  Widget buildTestableWidget({AccountCubit? cubit}) {
    return BlocProvider<AccountCubit>.value(
      value: cubit ?? buildMockAccountCubit(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NoticeListener(
            notices: controller.stream,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  testWidgets('shows a snackbar for every notice', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    controller.add(Exception('boom'));
    await tester.pumpAndSettle();
    expect(find.text('An unexpected error occurred: boom'), findsOneWidget);

    controller.add(Exception('second'));
    await tester.pumpAndSettle();
    expect(find.text('An unexpected error occurred: second'), findsOneWidget);
  });

  testWidgets('shows a message-only snackbar for non-auth errors', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    controller.add(Exception('boom'));
    await tester.pumpAndSettle();

    expect(find.text('An unexpected error occurred: boom'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
  });

  testWidgets('offers the auth action for auth notices', (tester) async {
    var signInCalls = 0;
    final cubit = buildMockAccountCubit(
      onSignIn: () async {
        signInCalls++;
        return AuthResult.authenticated;
      },
    );

    await tester.pumpWidget(buildTestableWidget(cubit: cubit));
    await tester.pumpAndSettle();

    controller.add(const MetadataAuthRequiredException('sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Metadata sign-in required.'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(signInCalls, 1);
  });
}
