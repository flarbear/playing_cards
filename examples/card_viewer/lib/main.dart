/*
 * Copyright 2021 flarbear@github
 *
 * Use of this source code is governed by a MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

import 'package:flutter/material.dart';

import 'package:playing_cards/playing_cards.dart';

main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Viewer',
      theme: ThemeData(),
      home: new CardViewer(title: 'Card Viewer', style: defaultCardStyle),
    );
  }
}

class CardViewer extends StatefulWidget {
  CardViewer({Key? key, required this.title, required this.style}) : super(key: key);

  final String title;
  final CardStyle style;

  @override
  _CardViewerState createState() => _CardViewerState();
}

class _CardViewerState extends State<CardViewer> {
  Widget _wrap(Widget child) {
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: SizedBox(
        width:   90,
        height: 140,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - ${widget.style.name}'),
      ),
      backgroundColor: Colors.green,
      body: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            children: <Widget>[
              for (int suit = 0; suit < widget.style.numSuits; suit++)
                Row(
                  children: <Widget>[
                    _wrap(SinglePlayingCard(null)),
                    _wrap(SinglePlayingCard(PlayingCard.back)),
                    for (int rank = 0; rank <= widget.style.numRanks; rank++)
                      _wrap(SinglePlayingCard(PlayingCard(suit: suit, rank:rank))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
