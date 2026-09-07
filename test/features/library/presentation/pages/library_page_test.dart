import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/library/presentation/pages/library_page.dart';

void main() {
  testWidgets('LibraryPage renders placeholder text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LibraryPage()));
    expect(find.text('Library Page'), findsOneWidget);
  });
}
