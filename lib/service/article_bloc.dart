import 'dart:async';

import 'package:flutter_board/model/article.dart';
import 'package:flutter_board/service/api.dart';
import 'package:meta/meta.dart';

import 'package:rxdart/rxdart.dart';

class ArticleBloc {
  final Api api;

  final _articlesController = PublishSubject<List<Article>>();

  ArticleBloc({@required this.api}) {}

  // Inputs
  void getArticles() async {
    _articlesController.add(await api.getArticles());
  }

  // Outputs
  Stream<List<Article>> get articles => _articlesController.stream;

  void close() {
    _articlesController.close();
  }
}
