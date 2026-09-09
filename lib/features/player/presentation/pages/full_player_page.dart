import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class FullPlayerPage extends StatelessWidget {
  final VoidCallback? onCollapse;

  const FullPlayerPage({super.key, this.onCollapse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => onCollapse?.call(),
        ),
      ),
      body: const Center(child: Text('Full Player UI - Step 11.5')),
    );
  }
}
