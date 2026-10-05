import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/features/home/presentation/cubit/home_state.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/browse_repository.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

class HomeCubit extends SafeCubit<HomeState> {
  final BrowseRepository _browse;
  final NoticeBus _notices;

  HomeCubit(this._browse, this._notices) : super(const HomeState());

  Future<void> fetchSections() async {
    if (!_browse.hasMetadata) {
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
      final browse = _browse;
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
      if (e.needsNotice) _notices.emit(Notice.error(e));
    }
  }

  void _fetchSectionItems(String sectionId) {
    _browse
        .sectionItems(sectionId, offset: 0, limit: 10)
        .then((itemsResult) {
          final List<Object> safeItems = itemsResult.items
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
        .catchError((Object e) {
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
          if (e.needsNotice) _notices.emit(Notice.error(e));
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
