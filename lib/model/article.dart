class Article {
  String? source;
  String? author;
  String? title;
  String? description;
  String? url;
  String? urlToImage;

  Article({
    this.source,
    this.author,
    this.title,
    this.description,
    this.url,
    this.urlToImage,
  });

  Article.fromJson(Map map) {
    source = map['source']['name'];
    author = map['author'];
    title = map['title'];
    description = map['description'];
    url = map['url'];
    // Some articles come with 'null' as a string
    String tempUrlToImage = map['urlToImage'] != 'null' ? map['urlToImage'] : null;
    // Used to correct some urls coming with 4 backslahes
    urlToImage = tempUrlToImage.replaceAll('////', '//');
  }
}
