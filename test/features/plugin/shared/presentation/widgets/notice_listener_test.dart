import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/notice_listener.dart';

import '../../../../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  late StreamController<Notice> controller;

  setUp(() {
    controller = StreamController<Notice>.broadcast();
  });

  tearDown(() async {
    await controller.close();
  });

  /// Mirrors `main.dart`: listener inside a root Scaffold, above the Navigator.
  Widget buildTestableWidget({UserCubit? cubit, Widget? home}) {
    return BlocProvider<UserCubit>.value(
      value: cubit ?? TestUserCubit(testUserState()),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Scaffold(
          resizeToAvoidBottomInset: false,
          body: NoticeListener(
            notices: controller.stream,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: home ?? const Scaffold(body: SizedBox.shrink()),
      ),
    );
  }

  testWidgets('shows a snackbar for every notice', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    controller.add(Notice.error(Exception('boom')));
    await tester.pumpAndSettle();
    expect(find.text('An unexpected error occurred: boom'), findsOneWidget);

    controller.add(Notice.error(Exception('second')));
    await tester.pumpAndSettle();
    expect(find.text('An unexpected error occurred: second'), findsOneWidget);
  });

  testWidgets('shows a message-only snackbar for non-auth errors', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    controller.add(Notice.error(Exception('boom')));
    await tester.pumpAndSettle();

    expect(find.text('An unexpected error occurred: boom'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('renders a neutral message notice without the error icon', (
    tester,
  ) async {
    var actionCalls = 0;
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    controller.add(
      Notice.message(
        'Already in Chill',
        action: (label: 'View', onAction: () => actionCalls++),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Already in Chill'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(actionCalls, 1);
  });

  testWidgets('offers the auth action for auth notices', (tester) async {
    var signInCalls = 0;
    final cubit = TestUserCubit(testUserState())
      ..onSignIn = () async {
        signInCalls++;
        return AuthResult.authenticated;
      };

    await tester.pumpWidget(buildTestableWidget(cubit: cubit));
    await tester.pumpAndSettle();

    controller.add(Notice.error(const MetadataAuthRequiredException('sign in')));
    await tester.pumpAndSettle();

    expect(find.text('Metadata sign-in required.'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(signInCalls, 1);
  });

  // Regression: the snackbar was rendered under modal routes (invisible
  // while a sheet or dialog was open).
  testWidgets('stays visible above an open modal route', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(title: Text('DIALOG')),
                );
                controller.add(Notice.error(Exception('boom')));
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('DIALOG'), findsOneWidget);
    final snack = find.text('An unexpected error occurred: boom');
    expect(snack, findsOneWidget);
    expect(snack.hitTestable(), findsOneWidget);
  });
}
