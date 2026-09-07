import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/models/section_state.dart';

void main() {
  group('SectionState Model Unit Tests', () {
    test('factory loading sets isLoading to true and clears error', () {
      const initial = SectionState<List<String>>(
        data: ['item1'],
        isLoading: false,
      );
      final loading = SectionState.loading(initial.data);

      expect(loading.isLoading, isTrue);
      expect(loading.hasError, isFalse);
      expect(loading.error, isNull);
      expect(loading.data, equals(['item1']));
    });

    test('factory success sets data and turns off isLoading', () {
      final success = SectionState.success(['item1', 'item2']);

      expect(success.isLoading, isFalse);
      expect(success.hasError, isFalse);
      expect(success.error, isNull);
      expect(success.data, equals(['item1', 'item2']));
    });

    test('factory error sets error and retains currentData', () {
      final exception = Exception('Failed to fetch');
      final errorState = SectionState.error(exception, ['stale_data']);

      expect(errorState.isLoading, isFalse);
      expect(errorState.hasError, isTrue);
      expect(errorState.error, equals(exception));
      expect(errorState.data, equals(['stale_data']));
    });
  });
}
