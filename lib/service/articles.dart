import 'dart:async' show Future;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_board/model/article.dart';

Future<String> _loadArticlesAsset() async {
  return await rootBundle.loadString('assets/data/articles.json');
}

List<Article> _parseJsonForArticles(String jsonString) {
  var localData = json.decode(jsonString);
  if (localData != null && localData["articles"] != null) {
    List<Article> articles = (localData["articles"] as List<dynamic>)
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
  return null;
}

Future<List<Article>> loadArticles() async {
  String jsonArticles = await _loadArticlesAsset();
  return _parseJsonForArticles(jsonArticles);
}

