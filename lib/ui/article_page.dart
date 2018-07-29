import 'package:flutter/material.dart';
import 'package:flutter_board/model/article.dart';
import 'package:flutter_board/service/article_bloc_provider.dart';

typedef void FlipBack({bool backToTop});

class ArticlePage extends StatelessWidget {
  final Article article;

  final FlipBack flipBack;

  final double height;

  ArticlePage(this.article, this.flipBack, this.height);

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    Icon _getMenuIcon(TargetPlatform platform) {
      assert(platform != null);
      switch (platform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          return const Icon(Icons.more_vert);
        case TargetPlatform.iOS:
          return const Icon(Icons.more_horiz);
      }
      return null;
    }

    return Container(
      color: Colors.white,
      height: height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          AppBar(
            leading: flipBack != null
                ? new IconButton(
                    icon: new Icon(Icons.arrow_back),
                    color: Colors.black87,
                    onPressed: flipBack,
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
              flipBack == null
                  ? new IconButton(
                      icon: new Icon(Icons.refresh),
                      //color: Colors.black87,
                      onPressed: () => ArticleBlocProvider
                          .of(context)
                          .getArticles(refresh: true),
                    )
                  : Container(),
              PopupMenuButton<String>(
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    flipBack == null
                        ? PopupMenuItem<String>(
                            value: 'sources',
                            child: Text('Select Sources'),
                          )
                        : PopupMenuItem<String>(
                            value: 'back',
                            child: Text('Back to Top'),
                          ),
                    PopupMenuItem<String>(
                      value: 'about',
                      child: Text('About'),
                    ),
                  ];
                },
                onSelected: (String value) {
                  if (value == 'back') {
                    flipBack(backToTop: true);
                  }
                },
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
                icon: Icon(Icons.favorite_border),
                onPressed: null,
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: null,
              ),
              IconButton(
                icon: _getMenuIcon(Theme.of(context).platform),
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
