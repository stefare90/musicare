import 'package:flutter/material.dart';

/// Centers [child] when there is room, scrolls when the viewport is short
/// (landscape, open keyboard): non-list states can never overflow.
class ScrollableCentered extends StatelessWidget {
  final Widget child;

  const ScrollableCentered({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
