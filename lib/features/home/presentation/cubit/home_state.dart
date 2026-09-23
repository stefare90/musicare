import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/section_state.dart';

class SectionWithItems {
  final Section section;
  final SectionState<List<Object>> itemsState;

  const SectionWithItems({
    required this.section,
    this.itemsState = const SectionState(data: [], isLoading: true),
  });
}

class HomeState {
  final List<SectionWithItems> sections;

  const HomeState({
    this.sections = const [
      SectionWithItems(
        section: Section(id: '0', title: ''),
      ),
      SectionWithItems(
        section: Section(id: '1', title: ''),
      ),
      SectionWithItems(
        section: Section(id: '2', title: ''),
      ),
    ],
  });

  bool get isLoading => sections.any((s) => s.itemsState.isLoading);

  bool get hasAnyDataLoaded =>
      sections.any((s) => s.itemsState.data.isNotEmpty);

  bool get hasError =>
      sections.isNotEmpty &&
      !isLoading &&
      !hasAnyDataLoaded &&
      sections.every((s) => s.itemsState.hasError);

  Object? get error {
    if (hasError) {
      for (final s in sections) {
        if (s.itemsState.hasError) return s.itemsState.error;
      }
    }
    return null;
  }

  HomeState copyWith({List<SectionWithItems>? sections}) {
    return HomeState(sections: sections ?? this.sections);
  }
}
