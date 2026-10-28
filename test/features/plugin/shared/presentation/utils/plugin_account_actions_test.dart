import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_account_actions.dart';

import '../../../../../helpers/plugin_session_cubit_test_helpers.dart';

void main() {
  Widget buildTestableWidget(
    TestPluginSessionCubit plugins, {
    required void Function(bool) onResult,
  }) {
    return BlocProvider<PluginSessionCubit>.value(
      value: plugins,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => onResult(
                await PluginAccountActions.signIn(context, PluginType.metadata),
              ),
              child: const Text('Sign in'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('returns true when the sign-in succeeds', (tester) async {
    var signedIn = false;
    final plugins = buildTestPluginSessionCubit();
    plugins.onSignIn = (type) =>
        plugins.setAuthState(type, const PluginAuthState.signedIn('listener'));

    await tester.pumpWidget(
      buildTestableWidget(plugins, onResult: (value) => signedIn = value),
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(signedIn, isTrue);
  });

  testWidgets('returns false when the form is cancelled', (tester) async {
    var signedIn = true;
    final plugins = buildTestPluginSessionCubit();

    await tester.pumpWidget(
      buildTestableWidget(plugins, onResult: (value) => signedIn = value),
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(signedIn, isFalse);
  });

  testWidgets('signOut delegates to the typed plugin', (tester) async {
    var logoutCalls = 0;
    final plugins = buildTestPluginSessionCubit()
      ..onSignOut = (type) {
        expect(type, PluginType.metadata);
        logoutCalls++;
      };

    await tester.pumpWidget(
      BlocProvider<PluginSessionCubit>.value(
        value: plugins,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    PluginAccountActions.signOut(context, PluginType.metadata),
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
