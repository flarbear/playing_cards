/*
 * Copyright 2021 flarbear@github
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

import 'dart:ui';

import 'package:flutter/foundation.dart';

class MoveState<ID> {
  const MoveState(this.from, this.selected, this.to);
  const MoveState.empty() : from = null, selected = false, to = null;
  const MoveState.from(this.from) : selected = false, to = null;

  final ID? from;
  final bool selected;
  final ID? to;

  MoveState<ID> withFrom(ID? from) => MoveState(from, selected, to);
  MoveState<ID> withSelected(bool selected) => MoveState(from, selected, to);
  MoveState<ID> withTo(ID? to) => MoveState(from, selected, to);

  @override
  int get hashCode {
    return hashValues(from, selected, to);
  }

  @override
  bool operator ==(Object other) {
    return other is MoveState
        && from     == other.from
        && selected == other.selected
        && to       == other.to;
  }
}

class Move<ID, S> {
  const Move.binary(this.from, this.to, {
    required this.canMove,
    required this.execute,
  });

  const Move.unary(ID id, {
    required this.canMove,
    required this.execute,
  }) : from = id, to = id;

  final ID from;
  final ID to;
  final bool Function(S state) canMove;
  final void Function(S state) execute;

  bool get isUnary => from == to;
}

class MoveTracker<ID, S> extends ValueNotifier<MoveState<ID>> {
  MoveTracker(this.gameState, this.allMoves) : super(const MoveState.empty());

  final S gameState;
  final Map<ID, Map<ID, Move<ID, S>>> allMoves;

  late final Set<ID> _trackedIds = {
    ...allMoves.keys,
    for (final subMap in allMoves.values)
      ...subMap.keys,
  };

  bool isTracking(ID type) {
    return _trackedIds.contains(type);
  }

  bool isHighlighted(ID type) {
    return (value.from == type || value.to == type);
  }

  void leaving(ID type) {
    if (value.selected) {
      if (value.to == type) {
        value = value.withTo(null);
      }
    } else if (value.from == type) {
      value = value.withFrom(null);
    }
  }

  void hoveringOver(ID type, bool click) {
    MoveState<ID> newState;
    if (value.selected) {
      Move<ID, S>? move = allMoves[value.from]?[type];
      if (move != null && move.canMove(gameState)) {
        if (click) {
          move.execute(gameState);
          newState = MoveState<ID>.empty();
        } else {
          newState = value.withTo(type);
        }
      } else {
        if (click) {
          newState = MoveState<ID>.empty();
        } else {
          newState = value.withTo(null);
        }
      }
    } else {
      Map<ID, Move<ID, S>>? possibleMoves = allMoves[type];
      if (possibleMoves != null && possibleMoves.values.any(((move) => move.canMove(gameState)))) {
        newState = MoveState<ID>.from(type);
        if (click) {
          Move<ID, S>? unaryMove = possibleMoves[type];
          if (unaryMove != null) {
            unaryMove.execute(gameState);
            newState = MoveState<ID>.empty();
          } else {
            newState = newState.withSelected(true);
          }
        }
      } else {
        newState = MoveState<ID>.empty();
      }
    }
    value = newState;
  }
}
