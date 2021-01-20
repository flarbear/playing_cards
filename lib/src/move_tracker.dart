/*
 * Copyright 2021 flarbear@github
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

class MoveState<ID> {
  MoveState(this.from, this.selected, this.to);
  MoveState.empty() : from = null, selected = false, to = null;
  MoveState.from(this.from) : selected = false, to = null;

  final ID? from;
  final bool selected;
  final ID? to;

  MoveState<ID> withFrom(ID? from) => MoveState(from, selected, to);
  MoveState<ID> withSelected(bool selected) => MoveState(from, selected, to);
  MoveState<ID> withTo(ID? to) => MoveState(from, selected, to);
}

abstract class CardGameState<ID> {
  MoveState<ID> getCurrentMove();
  setCurrentMove(MoveState<ID> moveState);
}

class Move<ID, S extends CardGameState<ID>> {
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

class MoveTracker<ID, S extends CardGameState<ID>> {
  MoveTracker(this.gameState, this.allMoves) {
    gameState.setCurrentMove(MoveState<ID>.empty());
  }

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
    MoveState<ID> moveState = gameState.getCurrentMove();
    return (moveState.from == type || moveState.to == type);
  }

  void leaving(ID type) {
    MoveState<ID> moveState = gameState.getCurrentMove();
    if (moveState.selected) {
      if (moveState.to == type) {
        gameState.setCurrentMove(moveState.withTo(null));
      }
    } else if (moveState.from == type) {
      gameState.setCurrentMove(moveState.withFrom(null));
    }
  }

  void hoveringOver(ID type, bool click) {
    final MoveState<ID> currentState = gameState.getCurrentMove();
    MoveState<ID> newState;
    if (currentState.selected) {
      Move<ID, S>? move = allMoves[currentState.from]?[type];
      if (move != null && move.canMove(gameState)) {
        if (click) {
          move.execute(gameState);
          newState = MoveState<ID>.empty();
        } else {
          newState = currentState.withTo(type);
        }
      } else {
        if (click) {
          newState = MoveState<ID>.empty();
        } else {
          newState = currentState.withTo(null);
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
    if (currentState.from     != newState.from ||
        currentState.selected != newState.selected ||
        currentState.to       != newState.to) {
      gameState.setCurrentMove(newState);
    }
  }
}
