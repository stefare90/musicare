import 'package:flutter/material.dart';

/// Keeps its [child] vertically centered when there is room, and lets it
/// scroll when the viewport is too short (e.g. landscape or keyboard open),
/// so non-list states can never trigger a `RenderFlex` overflow.
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
