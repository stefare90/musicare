import 'package:flutter/material.dart';

/// Single source of truth for the geometry of `MediaCard` and of every
/// skeleton that mimics it (section rows, media grids, search skeletons).
///
/// Every measurement that depends on accessibility font scaling is derived
/// from [TextScaler], so real cards and skeletons stay pixel-coherent and can
/// never overflow their cell, whatever the user's font size.
abstract final class MediaCardMetrics {
  // ── Horizontal rhythm ──────────────────────────────────────────────────

  /// Outer inset shared by grids, horizontal rows and section titles.
  static const double edgeInset = 16.0;

  /// Gap between two adjacent cards (grid columns/rows and horizontal rows).
  static const double gap = 12.0;

  // ── Card sizing ────────────────────────────────────────────────────────

  /// Soft lower bound for a grid card width.
  static const double minCardWidth = 130.0;

  /// Max cross-axis extent used to compute the grid column count.
  static const double maxCardWidth = 180.0;

  /// Fixed width of the cards inside a horizontal section row.
  static const double rowCardWidth = 150.0;

  // ── Shape & text ───────────────────────────────────────────────────────

  /// Corner radius shared by cards and skeletons.
  static const double radius = 14.0;

  static const double textHorizontalPadding = 8.0;
  static const double textVerticalPadding = 6.0;
  static const double titleSubtitleGap = 2.0;
  static const int titleMaxLines = 2;
  static const int subtitleMaxLines = 1;
  static const double sectionTitleHorizontalPadding = 16.0;
  static const double sectionTitleVerticalPadding = 8.0;

  /// Title style used by `MediaCard` and measured here.
  static TextStyle titleStyle(TextTheme theme) =>
      (theme.titleSmall ?? const TextStyle()).copyWith(height: 1.15);

  /// Subtitle style used by `MediaCard` and measured here.
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

  /// Height of the card text block (title + subtitle + vertical paddings) for
  /// the current [TextScaler]. Used to size both `MediaCard` and its skeleton.
  static double textBlockHeight(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    return textVerticalPadding * 2 +
        _lineHeight(titleStyle(theme), scaler) * titleMaxLines +
        titleSubtitleGap +
        _lineHeight(subtitleStyle(theme), scaler) * subtitleMaxLines;
  }

  /// Total height of a card whose square cover is [cardWidth] wide.
  static double cardHeight(BuildContext context, double cardWidth) =>
      cardWidth + textBlockHeight(context);

  /// Total height of the horizontal rows in a section row.
  static double rowHeight(BuildContext context) =>
      cardHeight(context, rowCardWidth);

  /// Height reserved for a section title, so its skeleton matches the real one.
  static double sectionTitleHeight(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    return _lineHeight(theme.titleLarge ?? const TextStyle(), scaler);
  }

  // ── Grid geometry ──────────────────────────────────────────────────────

  /// Number of columns for a viewport of [maxWidth] logical pixels.
  static int gridColumns(double maxWidth) {
    final usable = maxWidth - edgeInset * 2;
    if (usable <= 0) return 1;
    final columns = (usable / (maxCardWidth + gap)).ceil();
    if (columns < 2) return 2;
    if (columns > 8) return 8;
    return columns;
  }

  /// Rounds [pageSize] up to the nearest multiple of [columns] so paginated
  /// grids never end with a partially filled row.
  ///
  /// When [columns] is not a positive number the request is left untouched.
  static int pageSizeForColumns(int pageSize, int columns) {
    if (columns <= 0) return pageSize;
    return ((pageSize + columns - 1) ~/ columns) * columns;
  }

  /// Width of a single grid cell for [columns] columns in a [maxWidth] viewport.
  static double gridCellWidth(double maxWidth, int columns) {
    final usable = maxWidth - edgeInset * 2;
    if (columns <= 0) return usable;
    return (usable - gap * (columns - 1)) / columns;
  }

  /// Deterministic grid delegate guaranteeing a square cover plus an exact
  /// text block, so a `MediaCard` can never overflow its cell.
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
