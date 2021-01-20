/*
 * Copyright 2021 flarbear@github
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

import 'package:flutter_test/flutter_test.dart';

import 'package:playing_cards/playing_cards.dart';

void main() {
  test('check constructing standard cards', () {
    for (int suit = 0; suit < 4; suit++) {
      for (int rank = 1; rank <= 13; rank++) {
        final PlayingCard card = PlayingCard(suit: suit, rank: rank);
        expect(card.isWild, false);
        expect(card.isBack, false);
        expect(card, equals(PlayingCard(suit: suit, rank: rank)));
        expect(card, isNot(equals(PlayingCard.wild)));
        expect(card, isNot(equals(PlayingCard.back)));
        expect(PlayingCard.wild, isNot(equals(card)));
        expect(PlayingCard.back, isNot(equals(card)));

        final PlayingCard back = PlayingCard(suit: suit, rank: -rank);
        expect(back.isWild, false);
        expect(back.isBack, true);
        expect(back, equals(PlayingCard(suit: suit, rank: -rank)));
        expect(back, isNot(equals(PlayingCard.wild)));
        expect(PlayingCard.wild, isNot(equals(back)));
        if (suit == 0 && rank == 1) {
          expect(back, equals(PlayingCard.back));
          expect(PlayingCard.back, equals(back));
        } else {
          expect(back, isNot(equals(PlayingCard.back)));
          expect(PlayingCard.back, isNot(equals(back)));
        }
      }
    }
    expect(PlayingCard.wild, equals(PlayingCard.wild));
    expect(PlayingCard.wild, isNot(equals(PlayingCard.back)));
    expect(PlayingCard.wild.isWild, true);
    expect(PlayingCard.wild.isBack, false);
    expect(PlayingCard.back, equals(PlayingCard.back));
    expect(PlayingCard.back, isNot(equals(PlayingCard.wild)));
    expect(PlayingCard.back.isWild, false);
    expect(PlayingCard.back.isBack, true);
  });
}
