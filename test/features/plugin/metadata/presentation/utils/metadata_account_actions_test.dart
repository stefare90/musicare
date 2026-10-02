import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/utils/metadata_account_actions.dart';

import '../../../../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  Widget buildTestableWidget(
    AccountCubit cubit, {
    required void Function(bool) onResult,
  }) {
    return BlocProvider<AccountCubit>.value(
      value: cubit,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async =>
                  onResult(await MetadataAccountActions.signIn(context)),
              child: const Text('Sign in'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('reports a failed sign-in with a snackbar', (tester) async {
    var signedIn = true;
    final cubit = buildMockAccountCubit(
      onSignIn: () async => AuthResult.failed,
    );

    await tester.pumpWidget(
      buildTestableWidget(cubit, onResult: (value) => signedIn = value),
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Metadata sign-in failed. Please check your details and try again.',
      ),
      findsOneWidget,
    );
    expect(signedIn, isFalse);
  });

  testWidgets('stays silent when the form is cancelled', (tester) async {
    var signedIn = true;
    final cubit = buildMockAccountCubit(
      onSignIn: () async => AuthResult.cancelled,
    );

    await tester.pumpWidget(
      buildTestableWidget(cubit, onResult: (value) => signedIn = value),
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(signedIn, isFalse);
  });

  testWidgets('returns true when the sign-in succeeds', (tester) async {
    var signedIn = false;
    final cubit = buildMockAccountCubit(
      onSignIn: () async => AuthResult.authenticated,
    );

    await tester.pumpWidget(
      buildTestableWidget(cubit, onResult: (value) => signedIn = value),
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(signedIn, isTrue);
  });

  testWidgets('signOut logs the plugin out', (tester) async {
    var logoutCalls = 0;
    final cubit = buildMockAccountCubit(
      onSignOut: () async => logoutCalls++,
    );

    await tester.pumpWidget(
      BlocProvider<AccountCubit>.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MetadataAccountActions.signOut(context),
                child: const Text('Sign out'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(logoutCalls, 1);
  });
}
