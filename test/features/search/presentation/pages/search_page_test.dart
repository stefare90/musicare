import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/search/presentation/pages/search_page.dart';

void main() {
  testWidgets('SearchPage renders placeholder text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    expect(find.text('Search Page'), findsOneWidget);
  });
}
