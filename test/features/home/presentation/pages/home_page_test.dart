import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/features/home/presentation/pages/home_page.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/notice_listener.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockBrowseService extends Mock implements IBrowse {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine mockEngine;
  late MockMetadataPlugin mockMetadata;
  late MockBrowseService mockBrowse;

  setUp(() async {
    await sl.reset();

    mockEngine = MockPluginEngine();
    mockMetadata = MockMetadataPlugin();
    mockBrowse = MockBrowseService();

    sl.registerLazySingleton<MetadataPluginEngine>(() => mockEngine);
    sl.registerLazySingleton<NoticeBus>(() => NoticeBus());

    when(() => mockEngine.hasMetadata).thenReturn(true);
    when(() => mockEngine.metadata).thenReturn(mockMetadata);
    when(() => mockMetadata.browse).thenReturn(mockBrowse);
  });

  Widget buildTestableWidget({MetadataPluginCubit? metadataCubit}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NoticeListener(
        notices: sl<NoticeBus>().notices,
        child: BlocProvider<MetadataPluginCubit>.value(
          value: metadataCubit ?? buildMockMetadataPluginCubit(),
          child: const HomePage(),
        ),
      ),
    );
  }

  group('HomePage Widget Tests', () {
    testWidgets('renders sections and items when loaded successfully', (
      tester,
    ) async {
      final section = Section(
        id: '1',
        title: 'Featured Albums',
        description: 'Handpicked',
      );
      final album = Album(
        id: 'al1',
        name: 'Dark Side of the Moon',
        artists: [],
        releaseDate: '1973',
        externalUri: '',
        totalTracks: 10,
        albumType: AlbumType.album,
      );

      when(() => mockBrowse.sections(offset: 0, limit: 10)).thenAnswer(
        (_) async => PaginatedResult<Section>(
          items: [section],
          total: 1,
          offset: 0,
          limit: 10,
        ),
      );

      when(() => mockBrowse.sectionItems('1', offset: 0, limit: 10)).thenAnswer(
        (_) async => PaginatedResult<MediaItem>(
          items: [album],
          total: 1,
          offset: 0,
          limit: 10,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Featured Albums'), findsOneWidget);
      expect(find.text('Handpicked'), findsOneWidget);
      expect(find.text('Dark Side of the Moon'), findsOneWidget);
    });

    testWidgets('renders no content card when section list is empty', (
      tester,
    ) async {
      when(() => mockBrowse.sections(offset: 0, limit: 10)).thenAnswer(
        (_) async =>
            PaginatedResult<Section>(items: [], total: 0, offset: 0, limit: 10),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Content Available'), findsOneWidget);
    });

    testWidgets('announces an auth error with the sign-in invitation', (
      tester,
    ) async {
      when(() => mockBrowse.sections(offset: 0, limit: 10)).thenAnswer(
        (_) async => throw const MetadataAuthRequiredException('sign in'),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ErrorCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Metadata sign-in required.'),
        ),
        findsOneWidget,
      );
    });
  });
}
