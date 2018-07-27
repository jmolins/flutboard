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
      theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
          ),
      title: 'FlipPanel',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FlipPanel.fromItems(
          items: articles,
          itemBuilder: (context, article, onBackFlip) => ArticlePage(article, onBackFlip),
        ),
      ),
    );
  }
}
