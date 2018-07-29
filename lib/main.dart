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
        theme: ThemeData(
          primaryIconTheme: IconThemeData(color: Colors.black87),
        ),
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
