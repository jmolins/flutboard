import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_board/service/api.dart';
import 'package:flutter_board/service/article_bloc.dart';
import 'package:flutter_board/service/article_bloc_provider.dart';
import 'package:flutter_board/ui/article_page.dart';
import 'package:flutter_board/ui/my_flip_panel.dart';
import 'package:flutter/material.dart';

Future main() async {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    Api api = new Api();
    ArticleBloc bloc = ArticleBloc(api: api);

    bloc.getArticles();

    return ArticleBlocProvider(
      bloc: bloc,
      child: MaterialApp(
        title: 'FlutBoard',
        theme: _buildTheme(),
        home: HomePage(),
      ),
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
      // This Scaffold is used to display the FlipPane SnackBar. Later,
      // each article page will have its own Scaffold
      child: Scaffold(
        body: FlipPanel(
          itemStream: ArticleBlocProvider.of(context).articles,
          itemBuilder: (context, article, flipBack, height) =>
              ArticlePage(article, flipBack, height),
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
    accentColor: Colors.black87,
    primaryColor: const Color(0xFFF6F6F6),
    scaffoldBackgroundColor: const Color(0xFFF6F6F6),
    primaryIconTheme: base.iconTheme.copyWith(color: Colors.black87),
    iconTheme: base.iconTheme.copyWith(color: Colors.black87),
    textTheme: _buildShrineTextTheme(base.textTheme),
    primaryTextTheme: _buildShrineTextTheme(base.primaryTextTheme),
    accentTextTheme: _buildShrineTextTheme(base.accentTextTheme),
  );
}

TextTheme _buildShrineTextTheme(TextTheme base) {
  return base.apply(
    displayColor: Colors.black87,
    bodyColor: Colors.black87,
  );
}
