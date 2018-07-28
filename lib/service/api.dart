import 'dart:async';
import 'dart:convert';

import 'package:flutter_board/keys.dart';
import 'package:flutter_board/model/article.dart';
import 'package:http/http.dart' as http;

class Api {
  final String _baseUrl = "https://newsapi.org/v2/top-headlines?sources=";

  Future<List<Article>> getArticles() async {
    String url = Uri.encodeFull(_baseUrl + 'cnn,bbc-news');
    try {
      http.Response response = await http.get(url, headers: _headers());

      if (response.statusCode == 200) {
        var localData = json.decode(response.body);
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
      }
    } on Exception {}
    return [];
  }

  Map<String, String> _headers() {
    return {
      "Accept": "application/json",
      "X-Api-Key": NEWSAPI_KEY,
    };
  }
}
