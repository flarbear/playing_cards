/*
 * Copyright 2021 flarbear@github
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

import 'dart:math';
import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'playing_card.dart';

CardStyle defaultCardStyle = ClassicCardStyle();

abstract class CardStyle {
  const CardStyle();

  Size get preferredSize;
  double get cascadeOffset;
  double get aspectRatio => preferredSize.aspectRatio;

  String suitName(PlayingCard card);
  String rankName(PlayingCard card);
  String cardString(PlayingCard card);
  void drawCardBack(Canvas canvas);
  void drawCard(Canvas canvas, PlayingCard card);

  void drawTextAnchored(
      Canvas canvas,
      double textHeight,
      double maxWidth,
      Offset textAnchor,
      Offset cardAnchor,
      String text,
      Color color,
      String fontFamily) {
    TextSpan span = TextSpan(text: text, style: TextStyle(color: color, fontFamily: fontFamily));
    TextPainter tp = new TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    double scale = textHeight / tp.height;
    if (tp.width * scale > maxWidth) {
      scale = maxWidth / tp.width;
    }
    canvas.save();
    canvas.translate(cardAnchor.dx, cardAnchor.dy);
    canvas.scale(scale, scale);
    canvas.translate(-tp.width * textAnchor.dx, -tp.height * textAnchor.dy);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }
}

class ClassicCardStyle extends CardStyle {
  const ClassicCardStyle() : super();

  Size get preferredSize => const Size(90, 140);
  double get cascadeOffset => 25;

  static final Path heart = Path()
    ..moveTo(45, 55)
    ..cubicTo(45, 50, 52, 40, 60, 40)
    ..cubicTo(68, 40, 75, 47, 75, 55)
    ..cubicTo(75, 73, 47, 95, 45, 110)
    ..cubicTo(43, 95, 15, 73, 15, 55)
    ..cubicTo(15, 47, 22, 40, 30, 40)
    ..cubicTo(38, 40, 45, 50, 45, 55)
    ..close();

  static final Path diamond = Path()
    ..moveTo(45, 30)
    ..arcToPoint(Offset(20,  70), radius: Radius.elliptical(50, 70))
    ..arcToPoint(Offset(45, 110), radius: Radius.elliptical(50, 70))
    ..arcToPoint(Offset(70,  70), radius: Radius.elliptical(50, 70))
    ..arcToPoint(Offset(45,  30), radius: Radius.elliptical(50, 70))
    ..close();

  static final Path spade = Path()
    ..moveTo(45, 25)
    ..cubicTo(45, 45, 75, 55, 75, 70)
    ..cubicTo(75, 78, 68, 85, 60, 85)
    ..cubicTo(50, 85, 48, 74, 46, 70)
    ..cubicTo(46, 90, 50, 100, 69, 100)
    ..lineTo(70, 102)
    ..lineTo(20, 102)
    ..lineTo(21, 100)
    ..cubicTo(40, 100, 44, 90, 44, 70)
    ..cubicTo(42, 74, 40, 85, 30, 85)
    ..cubicTo(22, 85, 15, 78, 15, 70)
    ..cubicTo(15, 55, 45, 45, 45, 25)
    ..close();

  static final Path club = Path()
    ..arcTo(Rect.fromCircle(center: Offset(45, 45), radius: 17), pi / 2, 1.9 * pi, true)
    ..arcTo(Rect.fromCircle(center: Offset(60, 70), radius: 17), pi, 1.9 * pi, true)
    ..arcTo(Rect.fromCircle(center: Offset(30, 70), radius: 17), pi, 1.9 * pi, true)
    ..moveTo(45, 70)
    ..cubicTo(46, 90, 50, 100, 69, 100)
    ..lineTo(70, 102)
    ..lineTo(20, 102)
    ..lineTo(21, 100)
    ..cubicTo(40, 100, 44, 90, 44, 70)
    ..close();

  @override
  String suitName(PlayingCard card) {
    if (card.isBack) return 'unknown';
    if (card.isWild) return 'Joker';
    return [ 'Spades', 'Hearts', 'Diamonds', 'Clubs' ][card.suit & 3];
  }

  @override
  String rankName(PlayingCard card) {
    if (card.isBack) return 'unknown';
    return [ 'Joker', 'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen' ][card.rank];
  }

  @override
  String cardString(PlayingCard card) {
    if (card.isBack) return 'unknown';
    if (card.isWild) return 'Joker';
    return '${rankName(card)} of ${suitName(card)}';
  }

  static Path _makeZigZag() {
    Path p = Path();
    double x = 12.5;
    double y = 0;
    double xInc = 1.0;
    double yInc = 1.0;
    p.moveTo(x + 7.5, y + 7.5);
    for (int i = 0; i < 15; i++) {
      double dx = xInc > 0 ?  75 - x : x;
      double dy = yInc > 0 ? 125 - y : y;
      if (dx < dy) {
        x += xInc * dx; y += yInc * dx; xInc = -xInc;
      } else {
        x += xInc * dy; y += yInc * dy; yInc = -yInc;
      }
      p.lineTo(x + 7.5, y + 7.5);
    }
    p.close();
    return p;
  }

  static final Path zigzag = _makeZigZag();

  @override
  void drawCardBack(Canvas canvas) {
    Paint p = Paint();

    p.color = Color(0xFF1B5E20);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(7, 7, 83, 133), Radius.circular(5)), p);
    p.color = Color(0xFF795548);
    canvas.drawPath(zigzag, p);
  }

  @override
  void drawCard(Canvas canvas, PlayingCard card) {
    Paint p = Paint();

    String name;
    if (card.isWild) {
      name = r'$';
      p.color = Color(0xFF000000);
      drawTextAnchored(canvas, 42, 80, Offset(0.5, 0.5), Offset(45, 70), 'Joker', p.color, 'Tahoma');
    } else {
      Path suitPath = [ spade, heart, diamond, club ][card.suit & 3];
      p.color = [ Color(0xFF000000), Color(0xFFF44336), Color(0xFFF44336), Color(0xFF000000) ][card.suit & 3];
      canvas.drawPath(suitPath, p);
      name = rankName(card);
      if (name.length > 2) name = name.substring(0, 1);
    }

    drawTextAnchored(canvas, 28, 80, Offset.zero,  Offset( 7,   1), name, p.color, 'Tahoma');
    drawTextAnchored(canvas, 28, 80, Offset(1, 1), Offset(83, 137), name, p.color, 'Tahoma');
  }

  @override
  String toString() {
    return 'ClassicCardTheme()';
  }
}

class PlayingCardPainter extends CustomPainter {
  PlayingCardPainter(this.style, this.card, this.highlighted);

  final CardStyle style;
  final PlayingCard? card;
  bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint()
      ..strokeWidth = 1.0;

    Rect outlineBounds = (Offset.zero & size).deflate(0.5);
    RRect outline = RRect.fromRectAndRadius(outlineBounds, Radius.circular(5));

    if (card != null) {
      p.color = highlighted ? Color(0xFFC8E6C9) : Color(0xFFFFFFFF);
      canvas.drawRRect(outline, p);
      p.style = PaintingStyle.stroke;
      p.color = Color(0x42000000);
      canvas.drawRRect(outline, p);

      canvas.scale(
        size.width  / style.preferredSize.width,
        size.height / style.preferredSize.height,
      );
      if (card!.isBack) {
        style.drawCardBack(canvas);
      } else {
        style.drawCard(canvas, card!);
      }
    } else {
      if (highlighted) {
        p.color = Color(0x7F9E9E9E);
        canvas.drawRRect(outline, p);
      }
      p.color = Color(0xFFFFFFFF);
      p.style = PaintingStyle.stroke;
      canvas.drawRRect(outline, p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is PlayingCardPainter) {
      return oldDelegate.style != this.style
          || oldDelegate.card != this.card
          || oldDelegate.highlighted != this.highlighted;
    }
    return true;
  }
}
