import 'dart:async';
import 'dart:convert';

import 'package:flutboard/keys.dart';
import 'package:flutboard/model/source.dart';
import 'package:http/http.dart' as http;

class Api {
  final String _baseUrl = "https://newsapi.org/v2/";

  Future<String?> getArticles({
    required String sources,
    required int page,
    required int pageSize,
  }) async {
    String uri =
        Uri.encodeFull('${_baseUrl}top-headlines?sources=$sources&pageSize=$pageSize&page=$page');
    var url = Uri.parse(uri);
    try {
      http.Response response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        return response.body;
      }
      // ignore: empty_catches
    } on Exception {}
    return null;
  }

  Future<List<Source>?> getSources() async {
    String uri = Uri.encodeFull('${_baseUrl}sources');
    var url = Uri.parse(uri);
    try {
      http.Response response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data != null && data["sources"] != null) {
          List<Source> sources =
              (data["sources"] as List<dynamic>).map((source) => Source.fromJson(source)).toList();
          return sources;
        }
      }
      // ignore: empty_catches
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
