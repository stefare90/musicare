import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';
import 'package:music_are/features/library/presentation/pages/library_page.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

void main() {
  Widget buildTestableWidget(MetadataPluginCubit cubit) {
    return BlocProvider<MetadataPluginCubit>.value(
      value: cubit,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LibraryPage(),
      ),
    );
  }

  testWidgets('invites the user to sign in when signed out', (tester) async {
    var authenticateCalls = 0;
    final cubit = buildMockMetadataPluginCubit(
      state: testLoadedState(isAuthenticated: false),
      onAuthenticate: () async {
        authenticateCalls++;
        return AuthResult.authenticated;
      },
    );

    await tester.pumpWidget(buildTestableWidget(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Your library'), findsOneWidget);
    expect(
      find.text(
        'Sign in to see your saved tracks, albums, artists and playlists.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(authenticateCalls, 1);
  });

  testWidgets('shows the library skeleton when signed in', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        buildMockMetadataPluginCubit(
          state: testLoadedState(isAuthenticated: true, userName: 'listener'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SkeletonTrackList), findsOneWidget);
    expect(find.text('Your library'), findsNothing);
  });

  testWidgets('renders nothing when no plugin is loaded', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        buildMockMetadataPluginCubit(state: MetadataPluginNotConfiguredState()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SkeletonTrackList), findsNothing);
  });
}
