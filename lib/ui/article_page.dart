import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_board/model/article.dart';

class ArticlePage extends StatelessWidget {
  final Article article;

  final VoidCallback onFlipBack;

  final double height;

  ArticlePage(this.article, this.onFlipBack, this.height);

  @override
  Widget build(BuildContext context) {
    Future<Null> _showDialog(String message) async {
      return showDialog<Null>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text('Dialog'),
            content: Text(message),
            actions: <Widget>[
              new FlatButton(
                child: new Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    var screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.white,
      height: height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          AppBar(
            leading: onFlipBack != null
                ? new IconButton(
                    icon: new Icon(Icons.arrow_back),
                    color: Colors.black87,
                    onPressed: onFlipBack,
                  )
                : Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      'assets/images/flutboard_logo.png',
                    ),
                  ),
            title: Text(
              article.source,
              style: TextStyle(color: Colors.black87),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            actions: <Widget>[
              new IconButton(
                icon: new Icon(Icons.menu),
                color: Colors.black87,
                onPressed: () => _showDialog("Top menu pressed"),
              ),
            ],
          ),
          SizedBox(
            width: screenWidth,
            //height: screenWidth / 2,
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/images/1x1_transparent.png',
              image: article.urlToImage,
              width: screenWidth,
              height: screenWidth / 2,
              fadeInDuration: const Duration(milliseconds: 300),
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              article.title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Row(
              children: <Widget>[
                Text(
                  article.author ?? article.source,
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: new LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                print(constraints);
                return new Text(
                  article.description,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18.0, color: Colors.black54),
                  maxLines: (constraints.maxHeight / 18.0).floor() - 1,
                );
              }),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: Container()),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _showDialog("Plus icon pressed"),
              ),
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => _showDialog("Bottom menu pressed"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
