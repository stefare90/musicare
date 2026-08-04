import 'package:gyawun_metadata_sdk/metadata/models/section.dart';

class SectionWithItems {
  final Section section;
  final List<Object> items;

  SectionWithItems({required this.section, required this.items});
}

abstract class HomeState {}

class HomeInitialState extends HomeState {}

class HomeLoadingState extends HomeState {}

class HomeLoadedState extends HomeState {
  final List<SectionWithItems> sections;
  final bool isRefreshing;
  final Object? refreshError;

  HomeLoadedState({
    required this.sections,
    this.isRefreshing = false,
    this.refreshError,
  });

  HomeLoadedState copyWith({
    List<SectionWithItems>? sections,
    bool? isRefreshing,
    Object? refreshError,
  }) {
    return HomeLoadedState(
      sections: sections ?? this.sections,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: refreshError,
    );
  }
}

class HomeErrorState extends HomeState {
  final Object error;
  HomeErrorState(this.error);
}
