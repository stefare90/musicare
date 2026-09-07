import 'package:flutter/material.dart';

class FullPlayerPage extends StatelessWidget {
  const FullPlayerPage({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const FullPlayerPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(child: Text('Full Player UI - Step 11.5')),
    );
  }
}
