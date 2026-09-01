import 'package:gyawun_metadata_sdk/metadata/models/section.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/features/home/presentation/cubit/home_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

class HomeCubit extends SafeCubit<HomeState> {
  final MetadataPluginEngine _pluginEngine;

  HomeCubit(this._pluginEngine) : super(const HomeState());

  Future<void> fetchSections() async {
    if (!_pluginEngine.hasMetadata) {
      final err = PluginNotLoadedException();
      emit(
        HomeState(
          sections: [
            SectionWithItems(
              section: Section(id: '0', title: ''),
              itemsState: SectionState.error(err, const []),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final browse = _pluginEngine.metadata.browse;
      final sectionsResult = await browse.sections(offset: 0, limit: 10);

      if (sectionsResult.items.isEmpty) {
        emit(const HomeState(sections: []));
        return;
      }

      final initialSections = sectionsResult.items
          .map(
            (s) => SectionWithItems(
              section: s,
              itemsState: const SectionState(data: [], isLoading: true),
            ),
          )
          .toList();

      emit(HomeState(sections: initialSections));

      for (final sectionData in initialSections) {
        _fetchSectionItems(sectionData.section.id);
      }
    } catch (e) {
      emit(
        HomeState(
          sections: [
            SectionWithItems(
              section: Section(id: '0', title: ''),
              itemsState: SectionState.error(e, const []),
            ),
          ],
        ),
      );
    }
  }

  void _fetchSectionItems(String sectionId) {
    _pluginEngine.metadata.browse
        .sectionItems(sectionId, offset: 0, limit: 10)
        .then((itemsResult) {
          final List<Object> safeItems = itemsResult.items
              .where((item) => item != null)
              .cast<Object>()
              .toList();

          final updatedSections = state.sections.map((s) {
            if (s.section.id == sectionId) {
              return SectionWithItems(
                section: s.section,
                itemsState: SectionState.success(safeItems),
              );
            }
            return s;
          }).toList();

          emit(state.copyWith(sections: updatedSections));
        })
        .catchError((e) {
          final updatedSections = state.sections.map((s) {
            if (s.section.id == sectionId) {
              return SectionWithItems(
                section: s.section,
                itemsState: SectionState.error(e, s.itemsState.data),
              );
            }
            return s;
          }).toList();

          emit(state.copyWith(sections: updatedSections));
        });
  }

  Future<void> retrySection(String sectionId) async {
    final updatingSections = state.sections.map((s) {
      if (s.section.id == sectionId) {
        return SectionWithItems(
          section: s.section,
          itemsState: SectionState.loading(s.itemsState.data),
        );
      }
      return s;
    }).toList();

    emit(state.copyWith(sections: updatingSections));
    _fetchSectionItems(sectionId);
  }
}
