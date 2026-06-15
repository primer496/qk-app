import 'package:qk/models/sport.dart';
import 'package:qk/services/http_util.dart';
import 'package:qk/config/constants.dart';

class SportRepository {
  final HttpUtil _httpUtil = HttpUtil();

  Future<List<Sport>> getSportList() async {
    final data = await _httpUtil.getList(AppConstants.sportsUrl);
    return data.map((json) => Sport.fromJson(json)).toList();
  }
}