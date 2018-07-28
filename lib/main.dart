import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_board/model/article.dart';
import 'package:flutter_board/ui/article_page.dart';
import 'package:flutter_board/ui/my_flip_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_board/service/articles.dart';

List<Article> articles;

Future main() async {
  articles = await loadArticles();

  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      title: 'FlipPanel',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Calculate height of the page before applying the SafeArea since it removes
    // the padding from the MediaQuery and can not calculate it inside the page.
    double height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Scaffold(
        body: FlipPanel.fromItems(
          items: articles,
          itemBuilder: (context, article, onBackFlip, height) =>
              ArticlePage(article, onBackFlip, height),
          height: height,
        ),
      ),
    );
  }
}
