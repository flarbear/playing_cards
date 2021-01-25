/*
 * Copyright 2021 flarbear@github
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

import 'dart:ui';

import 'card_style.dart';

/// A single playing card in an arbitrary deck of cards that is divided
/// into numbered suits and numbered ranks and can be associated with
/// a [CardStyle] instance to interpret its visual representation and
/// its rank and suit naming.
///
/// A rank of 0 is considered by default to be a wild card for purposes
/// of the [isWild] property, but that association can be ignored for
/// usage with a conceptual set of cards which have no wild cards or
/// for usages where some ranked cards are considered wild. A constant
/// [PlayingCard.wild] instance is provided for convenience which
/// assumes a rank and suit index of `0`, but wild cards in specific
/// suits and with specific ranks can also be created using the
/// constructor.
///
/// Any negative rank is considered a face down card by the widgets
/// that display cards. A constant [PlayingCard.back] instance is
/// provided for convenience which assumes an index of `0` and a
/// rank of `-1`, but suited and ranked versions of face down cards
/// can be represented by constructing them with any negative rank.
///
/// The [style] property is provided to specifically associate a
/// given card instance with a specific [CardStyle] implementation,
/// but can be null if the style may vary from usage to usage or
/// if it is managed via a style property in the display widgets
/// instead. The only internal use of the style is in the toString()
/// method to form a human readable text representation and the
/// [defaultStyle] global variable will be used as a default if
/// the card is not constructed with an explicit style.
///
/// @see [CardStyle]
/// @see [ClassicCardStyle]
class PlayingCard {
  /// A convenient sample of a [PlayingCard] instance that represents
  /// a face down card with a suit of `0` and a rank of `-1`.
  static const PlayingCard back = const PlayingCard(suit: 0, rank: -1);

  /// A convenient sample of a [PlayingCard] instance that represents
  /// a wild card with a suit of '0' and a rank of '0'.
  static const PlayingCard wild = const PlayingCard(suit: 0, rank:  0);

  /// Constructs a playing card with the given [suit], [rank], and
  /// optional [isWild] and [style].
  ///
  /// If [isWild] is not specified then it will be assumed from
  /// the rank (`[rank] == 0`). If the [isWild] property is specified
  /// as `true` and a [rank] other than `0` is given, then the
  /// [style] should support [CardStyle.rendersWildRanks].
  const PlayingCard({
    required this.suit,
    required this.rank,
    bool? isWild,
    this.style,
  }) : this._isWild = isWild;

  /// Constructs a wild playing card with the given [suit] and
  /// an optional [rank] and [style].
  ///
  /// Ranked wild cards should only be used with [CardStyle]
  /// implementations that support rendering the ranks of
  /// wild cards.
  ///
  /// @see [CardStyle.rendersWildRanks]
  const PlayingCard.asWild({
    required this.suit,
    int? rank,
    this.style,
  }) : this.rank = rank ?? 0, this._isWild = true;

  /// The suit index of the card as semantically interpreted by the game
  /// logic and as visually interpreted by the [CardStyle] with which it
  /// will be rendered.
  ///
  /// The [ClassicCardStyle] interprets the index in the classic ordering
  /// used by Bridge: Spades, Hearts, Diamonds, Clubs.
  final int suit;

  /// The rank index of the card as semantically interpreted by the game
  /// logic and as visually interpreted by the [CardStyle] with which it
  /// will be rendered.
  ///
  /// The [ClassicCardStyle] interprets the index as ranging from a
  /// Joker at rank 0, an Ace at rank 1, up to a King at rank 13.
  final int rank;

  /// The [CardStyle] associated with this card, or null if the
  /// visual and textual interpretation of the card can be left up
  /// to multiple styles or if the style will be managed by the
  /// display widgets instead.
  final CardStyle? style;

  /// True if this card was explicitly designated as a wild card
  /// in the constructor or if it is implicitly wild due to being
  /// constructed with a rank of 0.
  bool get isWild => _isWild ?? (rank == 0);
  final bool? _isWild;

  /// A simple and common assessment as to whether this card is
  /// face down based on associating all negative ranks as being
  /// face down cards.
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

/// A representation of a stack of [PlayingCard] objects where
/// the cards are stacked directly on top of each other and only
/// the top card has a chance to be visible.
///
/// The stack can be empty if the [size] is zero, in which case the
/// [card] should be null.
///
/// The [top] card can be left face down or be visible by specifying
/// an instance with the appropriate value for [PlayingCard.isBack].
/// The size must not be `0` if the top card is not null.
class PlayingCardStack {
  /// Construct a stack of cards of the indicated size where the
  /// top card (if it exists) is not visible.
  PlayingCardStack.hidden(this.size) : this.top = size == 0 ? null : PlayingCard.back;

  /// Construct a stack of cards of the indicated size with the
  /// indicated top card.
  PlayingCardStack({ this.size = 0, this.top })
      : assert(size > 0 || top == null);

  /// Extract the info for a stack of cards from a list.
  PlayingCardStack.fromList(List<PlayingCard> cards)
      : this.size = cards.length,
        this.top = cards.isEmpty ? null : cards.last;

  /// The size of the stack of cards.
  final int size;

  /// The top card of the stack, or null if the stack is empty.
  final PlayingCard? top;
}
