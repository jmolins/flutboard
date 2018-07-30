import 'dart:async';
import 'dart:convert';

import 'package:flutter_board/model/article.dart';
import 'package:flutter_board/service/api.dart';
import 'package:meta/meta.dart';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleBloc {
  static const String _kSourcesKey = "sources_key";

  final Api api;

  static const int _pageSize = 10;
  int _nextPage = 1;

  // Assume there is at least one article in the server
  int _totalItemsForRequestedSources = 1;

  SharedPreferences prefs;
  Map<String, dynamic> sourcesMap;
  String sources;

  final _articlesController = PublishSubject<List<Article>>();

  ArticleBloc({@required this.api});

  void init() async {
    prefs = await SharedPreferences.getInstance();
    sourcesMap = readSources();
    sources = sourcesMapToUrlString();
  }

  // Inputs
  Future<void> getArticles({bool refresh = false}) async {
    if (sourcesMap == null) {
      await init();
    }
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
    String jsonString =
        await api.getArticles(sources: sources, page: page, pageSize: pageSize);
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

  Map<String, dynamic> readSources() {
    String sources = prefs.getString(_kSourcesKey);
    if (sources == null) {
      var map = {
        'cnn': {'name': 'CNN', 'active': true},
        'bbc-news': {'name': 'BBC News', 'active': true}
      };
      saveSources(map);
      return map;
    }
    Map<String, dynamic> map = json.decode(sources).cast<String, dynamic>();
    return map;
  }

  void saveSources(Map<String, dynamic> sourcesMap) {
    prefs.setString(_kSourcesKey, jsonEncode(sourcesMap));
  }

  /// Stores the string containing the sources that will be used in the url
  /// to fetch articles from the server
  /// TODO: this should be moved to the api
  String sourcesMapToUrlString() {
    String str = '';
    sourcesMap.forEach((source, value) {
      if (value['active']) str += "$source,";
    });
    if (str.endsWith(',')) {
      str = str.substring(0, str.length - 1);
    }
    return str;
  }
}
