import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  const ShimmerBox.expand({super.key, this.borderRadius})
    : width = double.infinity,
      height = double.infinity;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colorScheme.surface;
    final target = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // One tone above the current background (below it in light mode):
        // visible without jumping to white.
        final pulse = 0.05 + 0.05 * _animation.value;
        final start = Color.lerp(base, target, pulse)!;
        final middle = Color.lerp(base, target, pulse + 0.03)!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
            gradient: LinearGradient(
              colors: [start, middle, start],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}
