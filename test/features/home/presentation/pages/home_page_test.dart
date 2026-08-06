import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/ibrowse.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/section.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/home/presentation/pages/home_page.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';

class MockPluginEngine extends Mock implements PluginEngine {}

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

    sl.registerLazySingleton<PluginEngine>(() => mockEngine);

    when(() => mockEngine.hasMetadata).thenReturn(true);
    when(() => mockEngine.metadata).thenReturn(mockMetadata);
    when(() => mockMetadata.browse).thenReturn(mockBrowse);
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
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
        (_) async => PaginatedResult<Object>(
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
  });
}
