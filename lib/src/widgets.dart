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

  Size preferredSize(CardStyle tableauStyle, BuildContext context);
}

/// A widget that paints a playing card. The artwork will auto-scale to
/// the size of the space allocated to it, but the best results will occur
/// when the space has the aspect ratio suggested by the CardStyle.
class SinglePlayingCard<ID> extends PlayingCardItem<ID> {
  SinglePlayingCard(this.card, { ID? id, this.size })
      : super(id);

  final PlayingCard? card;
  final Size? size;

  @override
  Size preferredSize(CardStyle tableauStyle, BuildContext context) {
    return size ?? (card?.style ?? tableauStyle).preferredSize;
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
        aspectRatio: size?.aspectRatio ?? style.aspectRatio,
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

enum StackedPlayingCardsCaption {
  none,
  ranked,
  hover,
  small,
  smallNonZero,
  standard,
  standardNonZero,
}

class StackedPlayingCards<ID> extends PlayingCardItem<ID> {
  StackedPlayingCards(this.stack, { ID? id, this.caption = StackedPlayingCardsCaption.standard, })
      : super(id);

  StackedPlayingCards.hidden(int size, {
    ID? id,
    StackedPlayingCardsCaption caption = StackedPlayingCardsCaption.standard,
  })
      : this(PlayingCardStack.hidden(size), id: id, caption: caption);

  StackedPlayingCards.fromList(List<PlayingCard> cards, {
    ID? id,
    StackedPlayingCardsCaption caption = StackedPlayingCardsCaption.standard,
  })
      : this(PlayingCardStack.fromList(cards), id: id, caption: caption);

  final PlayingCardStack stack;
  final StackedPlayingCardsCaption caption;

  @override
  Size preferredSize(CardStyle tableauStyle, BuildContext context) {
    CardStyle style = stack.top?.style ?? tableauStyle;
    return style.preferredSize + Offset(0, _captionString != null ? 30 : 0);
  }

  String? get _captionString {
    switch (caption) {
      case StackedPlayingCardsCaption.standardNonZero:
        return stack.size == 0 ? '' : '(${stack.size} cards)';
      case StackedPlayingCardsCaption.standard:
        return stack.size == 0 ? '(empty)' : '(${stack.size} cards)';
      case StackedPlayingCardsCaption.smallNonZero:
        return stack.size == 0 ? '' : '(${stack.size})';
      case StackedPlayingCardsCaption.small:
        return '(${stack.size})';
      default:
        break;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Size size = preferredSize(TableauInfo.of(context)?.style ?? defaultCardStyle, context);
    String? captionString = _captionString;
    PlayingCard? top = stack.top;
    if (caption == StackedPlayingCardsCaption.ranked && top != null && top.isWild) {
      top = PlayingCard.asWild(suit: top.suit, rank: stack.size, style: top.style);
    }
    Widget widget = AspectRatio(
      aspectRatio: size.aspectRatio,
      child: Column(
        children: <Widget>[
          SinglePlayingCard(stack.size == 0 ? null : top, id: id),
          if (captionString != null)
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text(captionString),)),
        ],
      ),
    );
    if (caption == StackedPlayingCardsCaption.hover) {
      widget = Tooltip(
        message: stack.size == 0 ? '(empty)' : '${stack.size} cards',
        child: widget,
      );
    }
    return widget;
  }
}

class CascadedPlayingCards<ID> extends PlayingCardItem<ID> {
  CascadedPlayingCards(this.cards, this.minimumCards, { ID? id })
      : assert(minimumCards > 0),
        super(id);

  final List<PlayingCard> cards;
  final int minimumCards;

  @override
  Size preferredSize(CardStyle tableauStyle, BuildContext context) => _preferredSize(tableauStyle, null);

  Size _preferredSize(CardStyle tableauStyle, List<double>? cascadeOffsets) {
    double maxW = 0;
    double maxH = 0;
    double y = 0;
    for (int i = 0; i < minimumCards || i < cards.length; i++) {
      CardStyle style = (i < cards.length ? cards[i].style : null) ?? tableauStyle;
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
    Size size = _preferredSize(TableauInfo.of(context)?.style ?? defaultCardStyle, cascadeOffsets);
    double alignScale = 2.0 / cascadeOffsets.last;
    if (!alignScale.isFinite) alignScale = 1.0;
    return AspectRatio(
      aspectRatio: size.aspectRatio,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: SinglePlayingCard(null, id: cards.length == 0 ? id : null, size: size),
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
    this.scale = 1.0,
    this.insets = EdgeInsets.zero,
    required this.childId,
  });

  final double scale;
  final EdgeInsets insets;
  final ID childId;
}

class TableauRow<ID> {
  TableauRow({
    this.scale = 1.0,
    this.insets = EdgeInsets.zero,
    required this.items,
    this.innerItemPad = 5.0,
  });

  final double scale;
  final EdgeInsets insets;
  final List<TableauItem<ID>> items;
  final double innerItemPad;
}

class Tableau<ID> {
  Tableau({
    this.scale = 1.0,
    this.insets = const EdgeInsets.all(5.0),
    required this.rows,
    this.innerRowPad = 5.0,
  });

  final double scale;
  final EdgeInsets insets;
  final List<TableauRow<ID>> rows;
  final double innerRowPad;
}

typedef Size LayoutHelper<ID>(ID id, Offset pos);

class TableauLayoutDelegate<ID> extends MultiChildLayoutDelegate {
  TableauLayoutDelegate(this.spec, this.preferredSizes);

  final Tableau<ID> spec;
  final Map<ID, Size> preferredSizes;
  late final Size prefSize = _processSpec(1.0, false);

  Offset _processItem(TableauItem<ID> item, Offset pos, double scale, bool doPosition) {
    scale *= item.scale;
    pos += item.insets.topLeft * scale;
    if (doPosition) positionChild(item.childId as Object, pos);
    Size childSize = preferredSizes[item.childId]!;
    return pos.translate(
      (childSize.width  + item.insets.right) * scale,
      (childSize.height + item.insets.bottom) * scale,
    );
  }

  Offset _processRow(TableauRow<ID> row, Offset pos, double scale, bool doPosition) {
    scale *= row.scale;
    pos += row.insets.topLeft * scale;
    double maxY = pos.dy;
    for (int colIndex = 0; colIndex < row.items.length; colIndex++) {
      if (colIndex > 0) pos = pos.translate(row.innerItemPad * scale, 0.0);
      Offset childBottomRight = _processItem(row.items[colIndex], pos, scale, doPosition);
      maxY = max(maxY, childBottomRight.dy);
      pos = Offset(childBottomRight.dx, pos.dy);
    }
    return Offset(pos.dx + row.insets.right * scale, maxY + row.insets.bottom * scale);
  }

  Size _processSpec(double scale, bool doPosition) {
    scale *= spec.scale;
    Offset pos = spec.insets.topLeft * scale;
    double maxX = pos.dx;
    for (int rowIndex = 0; rowIndex < spec.rows.length; rowIndex++) {
      if (rowIndex > 0) pos = pos.translate(0.0, spec.innerRowPad * scale);
      Offset rowBottomRight = _processRow(spec.rows[rowIndex], pos, scale, doPosition);
      maxX = max(maxX, rowBottomRight.dx);
      pos = Offset(pos.dx, rowBottomRight.dy);
    }
    return Size(maxX + spec.insets.right * scale, pos.dy + spec.insets.bottom * scale);
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

    double tableauScale = scale * spec.scale;
    for (final row in spec.rows) {
      double rowScale = tableauScale * row.scale;
      for (final item in row.items) {
        Size childSize = preferredSizes[item.childId]!;
        layoutChild(item.childId as Object, BoxConstraints.tight(childSize * rowScale * item.scale));
      }
    }

    _processSpec(scale, true);
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
    this.backgroundColor,
  });

  final Widget? status;
  final Tableau<ID> tableauSpec;
  final Map<ID, PlayingCardItem<ID>> items;
  final MoveTracker<ID, S>? tracker;
  final CardStyle? style;
  final Color? backgroundColor;

  late final List<Widget> trackedChildren = items.entries.map((e) =>
      LayoutId(id: e.key as Object, child: track(e.key, e.value, tracker))
  ).toList();

  static Widget track<ID, S>(ID? id, Widget item, MoveTracker<ID, S>? tracker) {
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
    CardStyle tableauStyle = style ?? TableauInfo.of(context)?.style ?? defaultCardStyle;
    Widget child = Column(
      children: [
        if (status != null) status!,
        CustomMultiChildLayout(
          delegate: TableauLayoutDelegate(tableauSpec, items.map((id, item) =>
              MapEntry(id, item.preferredSize(tableauStyle, context))
          )),
          children: trackedChildren,
        ),
      ],
    );
    if (backgroundColor != null) {
      child = Container(color: backgroundColor, child: child);
    }
    child = FittedBox(
      fit: BoxFit.scaleDown,
      child: child,
    );
    return TableauInfo(
      tracker: tracker,
      style: tableauStyle,
      child: child,
    );
  }
}
