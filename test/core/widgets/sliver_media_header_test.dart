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
      bool optionsTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverMediaHeader(
            title: 'Help!',
            subtitle: 'Album • The Beatles',
            onSaveTap: () => saveTapped = true,
            onOptionsTap: () => optionsTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help!'), findsNWidgets(2));
      expect(find.text('Album • The Beatles'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      expect(saveTapped, isTrue);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(optionsTapped, isTrue);
    });
  });
}
