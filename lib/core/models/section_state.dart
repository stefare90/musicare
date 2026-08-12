class SectionState<T> {
  final T data;
  final bool isLoading;
  final Object? error;

  const SectionState({required this.data, this.isLoading = false, this.error});

  bool get hasError => error != null;

  factory SectionState.loading(T currentData) =>
      SectionState(data: currentData, isLoading: true, error: null);

  factory SectionState.success(T data) =>
      SectionState(data: data, isLoading: false, error: null);

  factory SectionState.error(Object error, T currentData) =>
      SectionState(data: currentData, isLoading: false, error: error);
}
