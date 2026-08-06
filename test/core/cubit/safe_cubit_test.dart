import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';

class TestSafeCubit extends SafeCubit<int> {
  TestSafeCubit() : super(0);

  void increment() => emit(state + 1);

  void tryEmitAfterClose() {
    close();
    emit(999);
  }
}

void main() {
  group('SafeCubit Unit Tests', () {
    test('emits state normally when active', () {
      final cubit = TestSafeCubit();
      expect(cubit.state, equals(0));

      cubit.increment();
      expect(cubit.state, equals(1));

      cubit.close();
    });

    test('does not throw StateError when emit is called after close', () {
      final cubit = TestSafeCubit();

      expect(() => cubit.tryEmitAfterClose(), returnsNormally);
      expect(cubit.isClosed, isTrue);
    });
  });
}
