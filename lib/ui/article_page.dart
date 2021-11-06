import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutboard/model/article.dart';
import 'package:flutboard/service/article_bloc_provider.dart';
import 'package:flutboard/ui/about_page.dart';
import 'package:flutboard/ui/sources_page.dart';
import 'package:url_launcher/url_launcher.dart';

typedef FlipBack = void Function({bool backToTop});

class ArticlePage extends StatefulWidget {
  final Article article;

  final FlipBack? flipBack;

  final double height;

  const ArticlePage({Key? key, required this.article, this.flipBack, required this.height})
      : super(key: key);

  @override
  ArticlePageState createState() {
    return ArticlePageState();
  }
}

class ArticlePageState extends State<ArticlePage> {
  Future<void> _selectSources(BuildContext context) async {
    String? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SourcesPage(bloc: ArticleBlocProvider.of(context))),
    );
    if (result == null) {
      ArticleBlocProvider.of(context).getArticles(refresh: true);
    }
  }

  Future<void> _aboutPage(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
  }

  _launchURL() async {
    String url = widget.article.url ?? '';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch $url")));
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    Icon _getMenuIcon(TargetPlatform platform) {
      switch (platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return const Icon(Icons.more_horiz);
        default:
          return const Icon(Icons.more_vert);
      }
    }

    Icon _getBackIcon(TargetPlatform platform) {
      switch (platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return const Icon(Icons.arrow_back_ios);
        default:
          return const Icon(Icons.arrow_back);
      }
    }

    return Container(
      color: Colors.white,
      height: widget.height,
      width: MediaQuery.of(context).size.width,
      child: WillPopScope(
        onWillPop: () {
          return Future(() {
            if (widget.flipBack == null) return true;
            widget.flipBack!();
            return false;
          });
        },
        child: Scaffold(
          appBar: AppBar(
            leading: widget.flipBack != null
                ? IconButton(
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
              widget.article.source ?? '',
              style: const TextStyle(color: Colors.black87),
            ),
            elevation: 0.0,
            centerTitle: true,
            actions: <Widget>[
              widget.flipBack == null
                  ? IconButton(
                      icon: const Icon(Icons.refresh),
                      //color: Colors.black87,
                      onPressed: () => ArticleBlocProvider.of(context).getArticles(refresh: true),
                    )
                  : Container(),
              PopupMenuButton<String>(
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    widget.flipBack == null
                        ? const PopupMenuItem<String>(
                            value: 'sources',
                            child: Text('Select Sources'),
                          )
                        : const PopupMenuItem<String>(
                            value: 'back',
                            child: Text('Back to Top'),
                          ),
                    const PopupMenuItem<String>(
                      value: 'about',
                      child: Text('About'),
                    ),
                  ];
                },
                onSelected: (String value) {
                  if (value == 'back' && widget.flipBack != null) {
                    widget.flipBack!(backToTop: true);
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
                  child:
                      widget.article.urlToImage != null && widget.article.urlToImage!.trim() != ""
                          ? FadeInImage.assetNetwork(
                              placeholder: 'assets/images/1x1_transparent.png',
                              image: widget.article.urlToImage!,
                              width: screenWidth,
                              height: screenWidth / 2,
                              fadeInDuration: const Duration(milliseconds: 300),
                              fit: BoxFit.cover,
                            )
                          : Container(),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    widget.article.title ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    // Be sure
                    widget.article.author != null && widget.article.author!.trim() != ""
                        ? widget.article.author!
                        : widget.article.source!,
                    style: const TextStyle(
                        fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: widget.article.description != null &&
                          widget.article.description!.trim() != ""
                      ? Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                            var maxLines = ((constraints.maxHeight / 18.0).floor() - 1);
                            return maxLines > 0
                                ? Text(
                                    widget.article.description!,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 18.0, color: Colors.black54),
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
                    const IconButton(
                      icon: Icon(Icons.favorite_border),
                      onPressed: null,
                    ),
                    const IconButton(
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
