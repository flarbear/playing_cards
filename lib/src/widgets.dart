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

abstract class PlayingCardItem<ID> extends StatelessWidget {
  PlayingCardItem(this.id);

  final ID? id;

  Size preferredSize(CardStyle? inheritedStyle);
}

/// A widget that paints a playing card. The artwork will auto-scale to
/// the size of the space allocated to it, but the best results will occur
/// when the space has the aspect ratio suggested by the CardStyle.
class SinglePlayingCard<ID> extends PlayingCardItem<ID> {
  SinglePlayingCard(this.card, { ID? id })
      : super(id);

  final PlayingCard? card;

  Size preferredSize(CardStyle? inheritedStyle) {
    CardStyle style =
        card?.style
            ?? inheritedStyle
            ?? defaultCardStyle;
    return style.preferredSize;
  }

  @override
  Widget build(BuildContext context) {
    TableauInfo? info = TableauInfo.of(context);
    CardStyle style =
        card?.style
            ?? info?.style
            ?? defaultCardStyle;
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: style.aspectRatio,
        child: CustomPaint(
          painter: PlayingCardPainter(style, card,
            id != null && (info?.tracker?.isHighlighted(id) ?? false),
          ),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

class StackedPlayingCards<ID> extends PlayingCardItem<ID> {
  StackedPlayingCards(this.stack, { ID? id })
      : super(id);

  StackedPlayingCards.hidden(int size, { ID? id })
      : this(PlayingCardStack.hidden(size), id: id);

  StackedPlayingCards.fromList(List<PlayingCard> cards, { ID? id })
      : this(PlayingCardStack.fromList(cards), id: id);

  final PlayingCardStack stack;

  @override
  Size preferredSize(CardStyle? inheritedStyle) {
    CardStyle style =
        stack.top?.style
            ?? inheritedStyle
            ?? defaultCardStyle;
    return style.preferredSize + Offset(0, 20);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SinglePlayingCard(stack.size == 0 ? null : stack.top, id: id),
        stack.size == 0 ? Text('(empty)') : Text('(${stack.size} cards)'),
      ],
    );
  }
}

class CascadedPlayingCards<ID> extends PlayingCardItem<ID> {
  CascadedPlayingCards(this.cards, this.minimumCards, { ID? id })
      : assert(minimumCards > 0),
        super(id);

  final List<PlayingCard> cards;
  final int minimumCards;

  @override
  Size preferredSize(CardStyle? inheritedStyle) => _preferredSize(inheritedStyle, null);

  Size _preferredSize(CardStyle? inheritedStyle, List<double>? cascadeOffsets) {
    CardStyle contextStyle = inheritedStyle ?? defaultCardStyle;
    double maxW = 0;
    double maxH = 0;
    double y = 0;
    for (int i = 0; i < minimumCards || i < cards.length; i++) {
      CardStyle style = (i < cards.length ? cards[i].style : null) ?? contextStyle;
      maxW = max(maxW, style.preferredSize.width);
      maxH = max(maxH, y + style.preferredSize.height);
      cascadeOffsets?.add(y);
      y += style.cascadeOffset;
    }
    return Size(maxW, maxH);
  }

  @override
  Widget build(BuildContext context) {
    List<double> cascadeOffsets = [];
    Size size = _preferredSize(TableauInfo.of(context)?.style, cascadeOffsets);
    double alignScale = 2.0 / cascadeOffsets.last;
    if (!alignScale.isFinite) alignScale = 1.0;
    return AspectRatio(
      aspectRatio: size.aspectRatio,
      child: Stack(
        children: <Widget>[
          if (cards.length == 0)
            Align(
              alignment: Alignment.topCenter,
              child: SinglePlayingCard(null, id: id),
            ),
          for (int i = 0; i < cards.length; i++)
            Align(
              alignment: Alignment(0, cascadeOffsets[i] * alignScale - 1),
              child: SinglePlayingCard(cards[i], id: i == cards.length - 1 ? id : null),
            ),
        ],
      ),
    );
  }
}

class TableauItem<ID> {
  TableauItem({
    this.insets = EdgeInsets.zero,
    required this.childId,
  });

  final EdgeInsets insets;
  final ID childId;
}

class TableauRow<ID> {
  TableauRow({
    this.insets = EdgeInsets.zero,
    required this.items,
    this.innerItemPad = 5.0,
  });

  final EdgeInsets insets;
  final List<TableauItem<ID>> items;
  final double innerItemPad;
}

class Tableau<ID> {
  Tableau({
    this.insets = const EdgeInsets.all(5.0),
    required this.rows,
    this.innerRowPad = 5.0,
  });

  final EdgeInsets insets;
  final List<TableauRow<ID>> rows;
  final double innerRowPad;
}

typedef Size LayoutHelper<ID>(ID id, Offset pos);

class TableauLayoutDelegate<ID> extends MultiChildLayoutDelegate {
  TableauLayoutDelegate(this.spec, this.preferredSizes);

  final Tableau<ID> spec;
  final Map<ID, Size> preferredSizes;
  late final Size prefSize = _processSpec(null);

  Offset _processItem(TableauItem<ID> item, Offset pos, double? scale) {
    pos += item.insets.topLeft;
    if (scale != null) positionChild(item.childId as Object, pos * scale);
    Size childSize = preferredSizes[item.childId]!;
    return pos.translate(
      childSize.width  + item.insets.right,
      childSize.height + item.insets.bottom,
    );
  }

  Offset _processRow(TableauRow<ID> row, Offset pos, double? scale) {
    pos += row.insets.topLeft;
    double maxY = pos.dy;
    for (int colIndex = 0; colIndex < row.items.length; colIndex++) {
      if (colIndex > 0) pos = pos.translate(row.innerItemPad, 0.0);
      Offset childBottomRight = _processItem(row.items[colIndex], pos, scale);
      maxY = max(maxY, childBottomRight.dy);
      pos = Offset(childBottomRight.dx, pos.dy);
    }
    return Offset(pos.dx + row.insets.right, maxY + row.insets.bottom);
  }

  Size _processSpec(double? scale) {
    Offset pos = spec.insets.topLeft;
    double maxX = pos.dx;
    for (int rowIndex = 0; rowIndex < spec.rows.length; rowIndex++) {
      if (rowIndex > 0) pos = pos.translate(0.0, spec.innerRowPad);
      Offset rowBottomRight = _processRow(spec.rows[rowIndex], pos, scale);
      maxX = max(maxX, rowBottomRight.dx);
      pos = Offset(pos.dx, rowBottomRight.dy);
    }
    return Size(maxX + spec.insets.right, pos.dy + spec.insets.bottom);
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

    for (final row in spec.rows) {
      for (final item in row.items) {
        Size childSize = preferredSizes[item.childId]!;
        layoutChild(item.childId as Object, BoxConstraints.tight(childSize * scale));
      }
    }

    _processSpec(scale);
  }

  bool _sameSizes(Map<dynamic, Size> oldSizes) {
    for (final row in spec.rows) {
      for (final item in row.items) {
        if (preferredSizes[item.childId] != oldSizes[item.childId]) return false;
      }
    }
    return true;
  }

  @override
  bool shouldRelayout(TableauLayoutDelegate oldDelegate) {
    return oldDelegate.spec != this.spec
        || !_sameSizes(oldDelegate.preferredSizes);
  }
}

class TableauInfo<ID> extends InheritedWidget {
  TableauInfo({this.tracker, this.style, required Widget child}) : super(child: child);

  final MoveTracker? tracker;
  final CardStyle? style;

  static TableauInfo? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TableauInfo>();
  }

  @override
  bool updateShouldNotify(TableauInfo oldWidget) {
    return oldWidget.tracker != this.tracker || oldWidget.style != this.style;
  }
}

class PlayingCardTableau<ID, S> extends StatelessWidget {
  PlayingCardTableau({
    required this.tableauSpec,
    required this.items,
    this.status,
    this.tracker,
    this.style,
  });

  final Widget? status;
  final Tableau<ID> tableauSpec;
  final Map<ID, PlayingCardItem<ID>> items;
  final MoveTracker<ID, S>? tracker;
  final CardStyle? style;

  late final Map<ID, Size> preferredSizes = items.map((id, item) =>
      MapEntry(id, item.preferredSize(style))
  );

  late final List<Widget> trackedChildren = items.entries.map((e) =>
      LayoutId(id: e.key as Object, child: track(e.key, e.value, tracker))
  ).toList();

  late final TableauLayoutDelegate<ID> delegate = TableauLayoutDelegate(tableauSpec, preferredSizes);

  static Widget track<ID, S>(ID id, PlayingCardItem<ID> item, MoveTracker<ID, S>? tracker) {
    if (tracker == null) return item;
    return GestureDetector(
      onTap: () => tracker.hoveringOver(id, true),
      child: MouseRegion(
        onHover: (event) => tracker.hoveringOver(id, false),
        onExit: (event) => tracker.leaving(id),
        child: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TableauInfo(
      tracker: tracker,
      style: style,
      child: Column(
        children: [
          if (status != null) status!,
          CustomMultiChildLayout(
            delegate: delegate,
            children: trackedChildren,
          ),
        ],
      ),
    );
  }
}
