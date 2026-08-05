import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/widgets/sliver_media_header.dart';

void main() {
  Widget buildTestableWidget({required SliverMediaHeader child}) {
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            child,
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ListTile(title: Text('Track #$index')),
                childCount: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  group('SliverMediaHeader Widget Tests', () {
    testWidgets('renders title, subtitle, and action buttons', (tester) async {
      bool saveTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverMediaHeader(
            title: 'Help!',
            subtitle: 'Album • The Beatles',
            onSaveTap: () => saveTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help!'), findsNWidgets(2));
      expect(find.text('Album • The Beatles'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      expect(saveTapped, isTrue);
    });

    testWidgets('renders filled heart when isSaved is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverMediaHeader(
            title: 'Help!',
            isSaved: true,
            onSaveTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets(
      'handles scroll drag and dynamic height measurement without errors',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const SliverMediaHeader(
              title: 'Abbey Road',
              subtitle: 'Album • The Beatles',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0.0, -300.0),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SliverMediaHeader), findsOneWidget);
      },
    );
  });
}
