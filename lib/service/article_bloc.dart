import 'dart:async';
import 'dart:convert';

import 'package:flutter_board/model/article.dart';
import 'package:flutter_board/service/api.dart';
import 'package:meta/meta.dart';

import 'package:rxdart/rxdart.dart';

class ArticleBloc {
  final Api api;

  static const int _pageSize = 10;
  int _nextPage = 1;

  // Assume there is at least one article in the server
  int _totalItemsForRequestedSources = 1;

  final _articlesController = PublishSubject<List<Article>>();

  ArticleBloc({@required this.api});

  // Inputs
  Future<void> getArticles({bool refresh = false}) async {
    List<Article> articles;
    if (refresh) {
      // Send a null list prior to the real list to allow the flip panel to reset
      // and show the refresh indicator
      _articlesController.add(null);
      articles = await _getArticles();
      _articlesController.add(articles);
      _nextPage = 2;
    } else {
      if (_totalItemsForRequestedSources > (_nextPage - 1) * _pageSize) {
        articles = await _getArticles(page: _nextPage);
        _articlesController.add(articles);
        _nextPage++;
      }
      // else no more items;
    }
  }

  // Outputs
  Stream<List<Article>> get articles => _articlesController.stream;

  void close() {
    _articlesController.close();
  }

  Future<List<Article>> _getArticles(
      {int page = 1, int pageSize = _pageSize}) async {
    String jsonString = await api.getArticles(page: page, pageSize: pageSize);
    if (jsonString != null) {
      var data = json.decode(jsonString);
      if (data != null &&
          data["totalResults"] != null &&
          data["articles"] != null) {
        _totalItemsForRequestedSources = data["totalResults"];
        List<Article> articles = (data["articles"] as List<dynamic>)
            .map((article) => Article(
                  article['source']['name'],
                  article['author'],
                  article['title'],
                  article['description'],
                  article['url'],
                  article['urlToImage'],
                ))
            .toList();
        return articles;
      }
    }
    return null;
  }
}
