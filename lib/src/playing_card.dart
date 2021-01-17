/*
 * Copyright 2021 flarbear@github
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

import 'dart:ui';

import 'card_style.dart';

class PlayingCard {
  static const PlayingCard back = const PlayingCard(suit: 0, rank: -1);
  static const PlayingCard wild = const PlayingCard(suit: 0, rank:  0);

  const PlayingCard({
    required this.suit,
    required this.rank,
    this.style,
  });

  final int suit;
  final int rank;
  final CardStyle? style;

  bool get isWild => rank == 0;
  bool get isBack => rank < 0;

  @override
  String toString() {
    return 'PlayingCard(${(style ?? defaultCardStyle).cardString(this)})';
  }

  @override
  int get hashCode {
    return hashValues(suit, rank);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayingCard
        && other.suit == this.suit
        && other.rank == this.rank;
  }
}
