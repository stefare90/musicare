import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/widgets/playback_progress_bar.dart';

class MockPlayerCubit extends Mock implements PlayerCubit {}

void main() {
  group('PlaybackProgressBar Widget Tests', () {
    late MockPlayerCubit mockPlayerCubit;

    setUp(() {
      mockPlayerCubit = MockPlayerCubit();
      when(
        () => mockPlayerCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
    });

    Widget buildTestableWidget({
      double height = 2.0,
      Color? color,
      Color? backgroundColor,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<PlayerCubit>.value(
            value: mockPlayerCubit,
            child: PlaybackProgressBar(
              height: height,
              color: color,
              backgroundColor: backgroundColor,
            ),
          ),
        ),
      );
    }

    testWidgets('calculates and renders progress ratio from PlayerState', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        const PlayerState(
          position: Duration(seconds: 30),
          duration: Duration(seconds: 60),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(indicator.value, equals(0.5));
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('handles zero duration gracefully without errors', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        const PlayerState(position: Duration.zero, duration: Duration.zero),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(indicator.value, equals(0.0));
    });

    testWidgets('renders custom height and custom colors', (tester) async {
      when(() => mockPlayerCubit.state).thenReturn(
        const PlayerState(
          position: Duration(seconds: 15),
          duration: Duration(seconds: 60),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          height: 4.0,
          color: Colors.red,
          backgroundColor: Colors.grey,
        ),
      );
      await tester.pumpAndSettle();

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(indicator.value, equals(0.25));
      expect(indicator.minHeight, equals(4.0));
      expect(indicator.backgroundColor, equals(Colors.grey));
    });
  });
}
