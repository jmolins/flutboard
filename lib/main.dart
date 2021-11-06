import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutboard/service/api.dart';
import 'package:flutboard/service/article_bloc.dart';
import 'package:flutboard/service/article_bloc_provider.dart';
import 'package:flutboard/ui/article_page.dart';
import 'package:flutboard/ui/flip_panel.dart';
import 'package:flutter/material.dart';

import 'model/article.dart';

Future main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    Api api = Api();
    ArticleBloc bloc = ArticleBloc(api: api);

    bloc.getArticles();

    return ArticleBlocProvider(
      bloc: bloc,
      child: MaterialApp(
        title: 'FlutBoard',
        theme: _buildTheme(),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate height of the page before applying the SafeArea since it removes
    // the padding from the MediaQuery and can not calculate it inside the page.
    double height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return SafeArea(
      // This Scaffold is used to display the FlipPane SnackBar. Later,
      // each article page will have its own Scaffold
      child: Scaffold(
        body: FlipPanel<Article>(
          itemStream: ArticleBlocProvider.of(context).articles,
          itemBuilder: <Article>(context, article, flipBack, height) =>
              ArticlePage(article: article, flipBack: flipBack, height: height),
          getItemsCallback: ArticleBlocProvider.of(context).getArticles,
          height: height,
        ),
      ),
    );
  }
}

ThemeData _buildTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    primaryIconTheme: base.iconTheme.copyWith(color: Colors.black87),
    iconTheme: base.iconTheme.copyWith(color: Colors.black87),
    textTheme: _buildShrineTextTheme(base.textTheme),
    primaryTextTheme: _buildShrineTextTheme(base.primaryTextTheme),
  );
}

TextTheme _buildShrineTextTheme(TextTheme base) {
  return base.apply(
    displayColor: Colors.black87,
    bodyColor: Colors.black87,
  );
}
