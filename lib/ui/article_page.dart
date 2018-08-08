import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutboard/model/article.dart';
import 'package:flutboard/service/article_bloc_provider.dart';
import 'package:flutboard/ui/about_page.dart';
import 'package:flutboard/ui/sources_page.dart';
import 'package:url_launcher/url_launcher.dart';

typedef void FlipBack({bool backToTop});

class ArticlePage extends StatefulWidget {
  final Article article;

  final FlipBack flipBack;

  final double height;

  ArticlePage(this.article, this.flipBack, this.height);

  @override
  ArticlePageState createState() {
    return new ArticlePageState();
  }
}

class ArticlePageState extends State<ArticlePage> {
  Future<Null> _selectSources(BuildContext context) async {
    String result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SourcesPage(ArticleBlocProvider.of(context))),
    );
    if (result == null) {
      ArticleBlocProvider.of(context).getArticles(refresh: true);
    }
  }

  Future<Null> _aboutPage(BuildContext context) async {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => AboutPage()));
  }

  _launchURL() async {
    String url = widget.article.url;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text("Could not launch $url")));
    }
  }

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

    Icon _getBackIcon(TargetPlatform platform) {
      assert(platform != null);
      switch (platform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          return const Icon(Icons.arrow_back);
        case TargetPlatform.iOS:
          return const Icon(Icons.arrow_back_ios);
      }
      return null;
    }

    return Container(
      color: Colors.white,
      height: widget.height,
      width: MediaQuery.of(context).size.width,
      child: WillPopScope(
        onWillPop: () {
          return new Future(() {
            if (widget.flipBack == null) return true;
            widget.flipBack();
            return false;
          });
        },
        child: Scaffold(
          appBar: AppBar(
            leading: widget.flipBack != null
                ? new IconButton(
                    icon: _getBackIcon(Theme.of(context).platform),
                    color: Colors.black87,
                    onPressed: widget.flipBack,
                  )
                : Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      'assets/images/flutboard_logo.png',
                    ),
                  ),
            title: Text(
              widget.article.source,
              style: TextStyle(color: Colors.black87),
            ),
            elevation: 0.0,
            centerTitle: true,
            actions: <Widget>[
              widget.flipBack == null
                  ? IconButton(
                      icon: new Icon(Icons.refresh),
                      //color: Colors.black87,
                      onPressed: () => ArticleBlocProvider.of(context)
                          .getArticles(refresh: true),
                    )
                  : Container(),
              PopupMenuButton<String>(
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    widget.flipBack == null
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
                    widget.flipBack(backToTop: true);
                  }
                  if (value == 'sources') {
                    _selectSources(context);
                  }
                  if (value == 'about') {
                    _aboutPage(context);
                  }
                },
              ),
            ],
          ),
          body: GestureDetector(
            onTap: _launchURL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: screenWidth,
                  child: widget.article.urlToImage != null &&
                          widget.article.urlToImage.trim() != ""
                      ? FadeInImage.assetNetwork(
                          placeholder: 'assets/images/1x1_transparent.png',
                          image: widget.article.urlToImage,
                          width: screenWidth,
                          height: screenWidth / 2,
                          fadeInDuration: const Duration(milliseconds: 300),
                          fit: BoxFit.cover,
                        )
                      : Container(),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    widget.article.title,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    // Be sure
                    widget.article.author != null &&
                            widget.article.author.trim() != ""
                        ? widget.article.author
                        : widget.article.source,
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: widget.article.description != null &&
                          widget.article.description.trim() != ""
                      ? Padding(
                          padding: EdgeInsets.all(10.0),
                          child: LayoutBuilder(builder: (BuildContext context,
                              BoxConstraints constraints) {
                            var maxLines =
                                ((constraints.maxHeight / 18.0).floor() - 1);
                            return maxLines > 0
                                ? Text(
                                    widget.article.description,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 18.0, color: Colors.black54),
                                    maxLines: maxLines,
                                  )
                                : Container();
                          }),
                        )
                      : Container(),
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
          ),
        ),
      ),
    );
  }
}
