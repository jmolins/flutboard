import 'dart:async';
import 'dart:convert';

import 'package:flutboard/model/article.dart';
import 'package:flutboard/model/source.dart';
import 'package:flutboard/service/api.dart';
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
  List<String> activeSources;
  String _activeSourcesStr;

  final _articlesController = PublishSubject<List<Article>>();
  final _sourcesController = PublishSubject<List<Source>>();

  ArticleBloc({@required this.api});

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    loadSources();
    _activeSourcesStr = sourcesListToUrlString();
  }

  void close() {
    _articlesController.close();
    _sourcesController.close();
  }

  // Inputs
  Future<void> getArticles({bool refresh = false}) async {
    if (activeSources == null) {
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
        if (articles != null) {
          _articlesController.add(articles);
          _nextPage++;
        }
      }
      // else no more items;
    }
  }

  Future<void> getSources() async {
    _sourcesController.add(await api.getSources());
  }

  // Outputs
  Stream<List<Article>> get articles => _articlesController.stream;

  Stream<List<Source>> get allSources => _sourcesController.stream;

  Future<List<Article>> _getArticles(
      {int page = 1, int pageSize = _pageSize}) async {
    String jsonString = await api.getArticles(
        sources: _activeSourcesStr, page: page, pageSize: pageSize);
    if (jsonString != null) {
      var data = json.decode(jsonString);
      if (data != null &&
          data["totalResults"] != null &&
          data["articles"] != null) {
        _totalItemsForRequestedSources = data["totalResults"];
        List<Article> articles = (data["articles"] as List<dynamic>)
            .map((article) => Article.fromJson(article))
            .toList();
        return articles;
      }
    }
    return null;
  }

  /// Loads active sources from localstorage
  void loadSources() {
    String sources = prefs.getString(_kSourcesKey);
    if (sources != null) {
      activeSources = json.decode(sources).cast<String>();
      if (activeSources.isNotEmpty) {
        return;
      }
    }
    // Getting here means we were not able to get valid sources
    activeSources = ['cnn', 'bbc-news'];
    saveSources();
    return;
  }

  /// Saves active sources to localstorage
  void saveSources() {
    prefs.setString(_kSourcesKey, jsonEncode(activeSources));
  }

  /// Converts the active sources list to a string that will be used in the url
  /// to fetch articles from the server
  /// TODO: this should be moved to the api
  String sourcesListToUrlString() {
    String str = '';
    activeSources.forEach((source) {
      str += "$source,";
    });
    if (str.endsWith(',')) {
      str = str.substring(0, str.length - 1);
    }
    return str;
  }

  /// Updates the active sources with the passed source id
  void activateSource({String id, bool activate}) {
    if (!activeSources.contains(id) && activate) {
      activeSources.add(id);
    } else if (activeSources.contains(id) && !activate) {
      activeSources.remove(id);
    }
    saveSources();
    _activeSourcesStr = sourcesListToUrlString();
  }
}
