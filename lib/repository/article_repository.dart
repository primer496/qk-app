import 'package:qk/models/article.dart';
import 'package:qk/services/http_util.dart';
import 'package:qk/config/constants.dart';

class ArticleRepository {
  final HttpUtil _httpUtil = HttpUtil();

  Future<List<Article>> getArticleList() async {
    final data = await _httpUtil.getList(AppConstants.articlesUrl);
    return data.map((json) => Article.fromJson(json)).toList();
  }

  Future<Article?> getArticleById(String id) async {
    final list = await getArticleList();
    return list.firstWhere((article) => article.id == id, orElse: () => Article(id: id, title: '', content: '', publishTime: ''));
  }
}