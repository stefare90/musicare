import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/utils/media_item_unboxer.dart';
import 'package:music_are/features/home/presentation/cubit/home_state.dart';
import 'package:music_are/features/plugin/data/exceptions/plugin_engine_exceptions.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';

class HomeCubit extends Cubit<HomeState> {
  final PluginEngine _pluginEngine;

  HomeCubit(this._pluginEngine) : super(HomeInitialState());

  Future<void> fetchSections() async {
    if (!_pluginEngine.hasMetadata) {
      emit(HomeErrorState(PluginNotLoadedException()));
      return;
    }

    if (state is HomeLoadedState &&
        (state as HomeLoadedState).sections.isNotEmpty) {
      final currentState = state as HomeLoadedState;
      emit(currentState.copyWith(isRefreshing: true, refreshError: null));
    } else {
      emit(HomeLoadingState());
    }

    try {
      final browse = _pluginEngine.metadata.browse;
      final sectionsResult = await browse.sections(offset: 0, limit: 10);

      final List<SectionWithItems> loadedSections = [];

      for (final section in sectionsResult.items) {
        final itemsResult = await browse.sectionItems(
          section.id,
          offset: 0,
          limit: 10,
        );
        final List<Object> safeItems = itemsResult.items
            .where((item) => item != null)
            .map((item) => unboxMediaItem(item))
            .toList();
        loadedSections.add(
          SectionWithItems(section: section, items: safeItems),
        );
      }

      emit(HomeLoadedState(sections: loadedSections, isRefreshing: false));
    } catch (e) {
      if (state is HomeLoadedState) {
        final currentState = state as HomeLoadedState;
        emit(currentState.copyWith(isRefreshing: false, refreshError: e));
      } else {
        emit(HomeErrorState(e));
      }
    }
  }
}
