class Article {
  final String id;
  final String title;
  final String content;
  final String publishTime;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.publishTime,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      publishTime: json['publish_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'publish_time': publishTime,
    };
  }
}