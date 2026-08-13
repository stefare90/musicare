import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/ibrowse.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/section.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/home/presentation/cubit/home_cubit.dart';
import 'package:music_are/features/home/presentation/cubit/home_state.dart';
import 'package:music_are/features/plugin/data/exceptions/plugin_engine_exceptions.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';

class MockPluginEngine extends Mock implements PluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockBrowseService extends Mock implements IBrowse {}

void main() {
  group('HomeCubit Unit Tests', () {
    late MockPluginEngine mockEngine;
    late MockMetadataPlugin mockMetadata;
    late MockBrowseService mockBrowse;
    late HomeCubit cubit;

    final testSection = const Section(
      id: 's1',
      title: 'Top Charts',
      description: 'Popular now',
    );
    final testAlbum = Album(
      id: 'al1',
      name: 'Album 1',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 10,
      albumType: AlbumType.album,
    );

    setUp(() {
      mockEngine = MockPluginEngine();
      mockMetadata = MockMetadataPlugin();
      mockBrowse = MockBrowseService();
      cubit = HomeCubit(mockEngine);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default skeleton sections', () {
      expect(cubit.state.sections.length, equals(3));
      expect(cubit.state.isLoading, isTrue);
    });

    test(
      'fetchSections sets error section when plugin is not loaded',
      () async {
        when(() => mockEngine.hasMetadata).thenReturn(false);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<HomeState>()
                .having((s) => s.hasError, 'hasError', isTrue)
                .having(
                  (s) => s.error,
                  'error',
                  isA<PluginNotLoadedException>(),
                ),
          ]),
        );

        await cubit.fetchSections();
      },
    );

    test(
      'fetchSections populates browse sections and items on success',
      () async {
        when(() => mockEngine.hasMetadata).thenReturn(true);
        when(() => mockEngine.metadata).thenReturn(mockMetadata);
        when(() => mockMetadata.browse).thenReturn(mockBrowse);

        when(() => mockBrowse.sections(offset: 0, limit: 10)).thenAnswer(
          (_) async => PaginatedResult<Section>(
            items: [testSection],
            total: 1,
            offset: 0,
            limit: 10,
          ),
        );

        when(
          () => mockBrowse.sectionItems('s1', offset: 0, limit: 10),
        ).thenAnswer(
          (_) async => PaginatedResult<Object>(
            items: [testAlbum],
            total: 1,
            offset: 0,
            limit: 10,
          ),
        );

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<HomeState>().having(
              (s) => s.sections.length,
              'sections length',
              1,
            ),
            isA<HomeState>()
                .having(
                  (s) => s.sections.first.itemsState.data.length,
                  'items length',
                  1,
                )
                .having(
                  (s) => s.sections.first.section.title,
                  'section title',
                  'Top Charts',
                ),
          ]),
        );

        await cubit.fetchSections();
      },
    );
  });
}
