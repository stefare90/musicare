import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/error_card.dart';
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

  testWidgets('shows the auth error card when signed out', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        buildMockMetadataPluginCubit(
          state: testLoadedState(isAuthenticated: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorCard), findsOneWidget);
    expect(find.text('Metadata sign-in required.'), findsOneWidget);
    expect(find.byType(SkeletonTrackList), findsNothing);
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
    expect(find.byType(ErrorCard), findsNothing);
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
    expect(find.byType(ErrorCard), findsNothing);
  });
}
