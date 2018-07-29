import 'dart:async';

import 'package:flutter_board/keys.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

class Api {
  final String _baseUrl = "https://newsapi.org/v2/top-headlines?sources=";

  Future<String> getArticles({
    @required int page,
    @required int pageSize,
  }) async {
    String url = Uri.encodeFull(_baseUrl + 'cnn,bbc-news&pageSize=$pageSize&page=$page');
    try {
      http.Response response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        return response.body;
      }
    } on Exception {}
    return null;
  }

  Map<String, String> _headers() {
    return {
      "Accept": "application/json",
      "X-Api-Key": NEWSAPI_KEY,
    };
  }
}
