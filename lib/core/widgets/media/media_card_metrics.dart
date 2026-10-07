import 'package:flutter/material.dart';

/// Single source of truth for card and skeleton geometry. Font-scaling
/// dependent measurements derive from [TextScaler], so cards and skeletons
/// stay coherent and never overflow.
abstract final class MediaCardMetrics {
  static const double edgeInset = 16.0;

  static const double gap = 12.0;

  static const double minCardWidth = 130.0;

  static const double maxCardWidth = 180.0;

  static const double rowCardWidth = 150.0;

  static const double radius = 14.0;

  static const double textHorizontalPadding = 8.0;
  static const double textVerticalPadding = 6.0;
  static const double titleSubtitleGap = 2.0;
  static const int titleMaxLines = 2;
  static const int subtitleMaxLines = 1;
  static const double sectionTitleHorizontalPadding = 16.0;
  static const double sectionTitleVerticalPadding = 8.0;

  static TextStyle titleStyle(TextTheme theme) =>
      (theme.titleSmall ?? const TextStyle()).copyWith(height: 1.15);

  static TextStyle subtitleStyle(TextTheme theme) =>
      theme.labelSmall ?? const TextStyle();

  static double _lineHeight(TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: 'Mg', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return painter.preferredLineHeight;
  }

  static double textBlockHeight(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    return textVerticalPadding * 2 +
        _lineHeight(titleStyle(theme), scaler) * titleMaxLines +
        titleSubtitleGap +
        _lineHeight(subtitleStyle(theme), scaler) * subtitleMaxLines;
  }

  static double cardHeight(BuildContext context, double cardWidth) =>
      cardWidth + textBlockHeight(context);

  static double rowHeight(BuildContext context) =>
      cardHeight(context, rowCardWidth);

  static double sectionTitleHeight(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    return _lineHeight(theme.titleLarge ?? const TextStyle(), scaler);
  }

  static int gridColumns(double maxWidth) {
    final usable = maxWidth - edgeInset * 2;
    if (usable <= 0) return 1;
    final columns = (usable / (maxCardWidth + gap)).ceil();
    if (columns < 2) return 2;
    if (columns > 8) return 8;
    return columns;
  }

  /// Rounds [pageSize] up to a multiple of [columns]; a non-positive column
  /// count leaves the request untouched.
  static int pageSizeForColumns(int pageSize, int columns) {
    if (columns <= 0) return pageSize;
    return ((pageSize + columns - 1) ~/ columns) * columns;
  }

  static double gridCellWidth(double maxWidth, int columns) {
    final usable = maxWidth - edgeInset * 2;
    if (columns <= 0) return usable;
    return (usable - gap * (columns - 1)) / columns;
  }

  static SliverGridDelegateWithFixedCrossAxisCount gridDelegate({
    required double maxWidth,
    required double textBlockHeight,
  }) {
    final columns = gridColumns(maxWidth);
    final cellWidth = gridCellWidth(maxWidth, columns);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      mainAxisExtent: cellWidth + textBlockHeight,
    );
  }
}
