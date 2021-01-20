/*
 * Copyright 2021 flarbear@github
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

import 'dart:math';

import 'package:flutter/material.dart';

import 'card_style.dart';
import 'move_tracker.dart';
import 'playing_card.dart';

abstract class TrackableCardGroup extends StatelessWidget {
  TrackableCardGroup(this.highlighted, CardStyle? style)
      : this.style = style ?? defaultCardStyle;

  final bool highlighted;
  final CardStyle style;

  static Widget track<ID>(
      MoveTracker<ID, CardGameState<ID>>? tracker,
      ID id,
      bool addLayout,
      Widget child,
      ) {
    if (tracker != null) {
      child = GestureDetector(
        onTap: () => tracker.hoveringOver(id, true),
        child: MouseRegion(
          onHover: (event) => tracker.hoveringOver(id, false),
          onExit: (event) => tracker.leaving(id),
          child: child,
        ),
      );
    }
    if (addLayout) child = LayoutId(id: id as Object, child: child);
    return child;
  }
}

/// A widget that paints a playing card. The artwork will auto-scale to
/// the size of the space allocated to it, but the best results will occur
/// when the space has the aspect ratio suggested by the CardStyle.
class PlayingCardWidget extends TrackableCardGroup {
  PlayingCardWidget(PlayingCard? card, {
    bool highlighted = false,
    CardStyle? style,
  })
      : this.card = card,
        super(highlighted, style ?? card?.style);

  static Widget tracked<ID>(
      MoveTracker<ID, CardGameState<ID>>? tracker,
      ID id,
      bool addLayout,
      PlayingCard? card, {
        CardStyle? style,
      }) {
    return TrackableCardGroup.track(tracker, id, addLayout,
      PlayingCardWidget(card,
        highlighted: tracker?.isHighlighted(id) ?? false,
        style: style,
      ),
    );
  }

  final PlayingCard? card;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: style.aspectRatio,
        child: CustomPaint(
          painter: PlayingCardPainter(style, card, highlighted),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

class PlayingCardStackWidget extends TrackableCardGroup {
  PlayingCardStackWidget(this.stack, {
    bool highlighted = false,
    CardStyle? style,
  }) : super(highlighted, style);

  static Widget tracked<ID>(
      MoveTracker<ID, CardGameState<ID>>? tracker,
      ID id,
      bool addLayout,
      PlayingCardStack stack, {
        CardStyle? style,
      }) {
    return TrackableCardGroup.track(tracker, id, addLayout,
      PlayingCardStackWidget(stack,
        highlighted: tracker?.isHighlighted(id) ?? false,
        style: style,
      ),
    );
  }

  final PlayingCardStack stack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        PlayingCardWidget(stack.size == 0 ? null : stack.top,
          highlighted: highlighted,
          style: style,
        ),
        stack.size == 0 ? Text('(empty)') : Text('(${stack.size} cards)'),
      ],
    );
  }
}

class PlayingCardPileWidget extends TrackableCardGroup {
  PlayingCardPileWidget(this.cards, this.minimumCards, {
    bool highlighted = false,
    CardStyle? style,
  }) : super(highlighted, style);

  final List<PlayingCard> cards;
  final int minimumCards;

  static Widget tracked<ID>(
      MoveTracker<ID, CardGameState<ID>>? tracker,
      ID id,
      bool addLayout,
      List<PlayingCard> cards,
      int minimumSize) {
    return TrackableCardGroup.track(tracker, id, addLayout,
        PlayingCardPileWidget(cards, minimumSize,
          highlighted: tracker?.isHighlighted(id) ?? false,
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    int offsets = max(max(minimumCards, cards.length) - 1, 0);
    double relativeH = offsets * style.cascadeOffset + style.height;
    double alignOffset = min(2.0 / offsets, 2.0);
    return AspectRatio(
      aspectRatio: 90 / relativeH,
      child: Stack(
        children: <Widget>[
          if (cards.length == 0)
            Align(
              alignment: Alignment.topCenter,
              child: PlayingCardWidget(null, highlighted: highlighted, style: style,),
            ),
          for (int i = 0; i < cards.length; i++)
            Align(
              alignment: Alignment(0, i * alignOffset - 1),
              child: PlayingCardWidget(cards[i], highlighted: highlighted && i == cards.length - 1, style: style,),
            ),
        ],
      ),
    );
  }
}

class TableauEntry {
  TableauEntry({
    this.insets = EdgeInsets.zero,
    required this.childId,
  });

  final EdgeInsets insets;
  final Object childId;
}

class TableauRowSpec {
  TableauRowSpec({
    this.insets = EdgeInsets.zero,
    required this.groups,
    this.innerGroupPad = 5.0,
  });

  final EdgeInsets insets;
  final List<TableauEntry> groups;
  final double innerGroupPad;
}

class TableauSpec {
  TableauSpec({
    this.insets = const EdgeInsets.all(5.0),
    required this.rows,
    this.innerRowPad = 5.0,
  });

  final EdgeInsets insets;
  final List<TableauRowSpec> rows;
  final double innerRowPad;
}

class TableauLayoutBase extends MultiChildLayoutDelegate {
  TableauLayoutBase(this.spec, this.style, {
    double? cardWidth,
    List<double>? rowHeights,
    double? rowHeight,
  })
      : cardWidth = cardWidth ?? style.width,
        rowHeights = rowHeights ?? List.filled(spec.rows.length, rowHeight ?? style.height);

  final TableauSpec spec;
  final CardStyle style;
  final double cardWidth;
  final List<double> rowHeights;
  late Size prefSize = _prefSize();

  Offset _processEntry(int rowIndex, int colIndex, Offset pos, double? scale, Map<Object, Size>? sizes) {
    var entry = spec.rows[rowIndex].groups[colIndex];
    pos += entry.insets.topLeft;
    if (scale != null) positionChild(entry.childId, pos);
    Size? childSize = sizes?[entry.childId];
    if (childSize == null) {
      pos = pos.translate(cardWidth, rowHeights[rowIndex]);
    } else {
      pos = pos.translate(childSize.width, childSize.height);
    }
    pos = pos - entry.insets.bottomRight;
    return pos;
  }

  Offset _processOneRow(int rowIndex, Offset pos, double? scale, Map<Object, Size>? sizes) {
    final row = spec.rows[rowIndex];
    pos += row.insets.topLeft;
    double maxY = pos.dy;
    for (int colIndex = 0; colIndex < row.groups.length; colIndex++) {
      if (colIndex > 0) pos = pos.translate(row.innerGroupPad, 0.0);
      Offset childBottomRight = _processEntry(rowIndex, colIndex, pos, scale, sizes);
      maxY = max(maxY, childBottomRight.dy);
      pos = Offset(childBottomRight.dx, pos.dy);
    }
    return Offset(pos.dx, maxY) - row.insets.bottomRight;
  }

  Offset _processRows(double? scale, Map<Object, Size>? sizes) {
    Offset pos = spec.insets.topLeft;
    double maxX = pos.dx;
    for (int rowIndex = 0; rowIndex < spec.rows.length; rowIndex++) {
      if (rowIndex > 0) pos = pos.translate(0.0, spec.innerRowPad);
      Offset rowBottomRight = _processOneRow(rowIndex, pos, scale, sizes);
      maxX = max(maxX, rowBottomRight.dx);
      pos = Offset(pos.dx, rowBottomRight.dy);
    }
    return Offset(maxX, pos.dy) - spec.insets.bottomRight;
  }

  Size _prefSize() {
    Offset maxPos = _processRows(null, null);
    return Size(maxPos.dx, maxPos.dy);
  }

  @override
  Size getSize(BoxConstraints constraints) {
    double prefW = prefSize.width;
    double prefH = prefSize.height;

    if (prefW < constraints.minWidth) {
      prefH = constraints.minWidth * prefH / prefW;
      prefW = constraints.minWidth;
    }
    if (prefH < constraints.minHeight) {
      prefW = constraints.minHeight * prefW / prefH;
      prefH = constraints.minHeight;
    }
    if (prefW > constraints.maxWidth) {
      prefH = constraints.maxWidth * prefH / prefW;
      prefW = constraints.maxWidth;
    }
    if (prefH > constraints.maxHeight) {
      prefW = constraints.maxHeight * prefW / prefH;
      prefH = constraints.maxHeight;
    }

    return Size(prefW, prefH);
  }

  @override
  void performLayout(Size size) {
    double scale = size.width / prefSize.width;
    BoxConstraints constraints = BoxConstraints.tightFor(width: scale * cardWidth);

    Map<Object, Size> childSizes = {};
    for (final row in spec.rows) {
      for (final entry in row.groups) {
        childSizes[entry.childId] = layoutChild(entry.childId, constraints);
      }
    }

    _processRows(scale, childSizes);
  }

  static bool _sameRowHeights(List<double> rows1, List<double> rows2) {
    if (rows1.length != rows2.length) return false;
    for (int i = 0; i < rows1.length; i++) {
      if (rows1[i] != rows2[i]) return false;
    }
    return true;
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    if (oldDelegate is TableauLayoutBase) {
      return oldDelegate.spec != this.spec
          || oldDelegate.style != this.style
          || oldDelegate.cardWidth != this.cardWidth
          || !_sameRowHeights(oldDelegate.rowHeights, this.rowHeights);
    }
    return true;
  }
}
