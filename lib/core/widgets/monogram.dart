import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';

/// Circular avatar with the initials of [name], or a person icon when there is
/// no identity to show.
class Monogram extends StatelessWidget {
  final String? name;
  final double radius;

  const Monogram({super.key, required this.name, this.radius = 14.0});

  static String? _initials(String? name) {
    if (name == null) return null;
    final parts = name
        .trim()
        .split(RegExp(r'[\s_.\-]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    if (initials == null) {
      return Icon(Icons.person, size: radius * 1.6);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: context.colorScheme.primaryContainer,
      child: Text(
        initials,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
