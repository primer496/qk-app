import 'package:qk/models/food.dart';
import 'package:qk/services/http_util.dart';
import 'package:qk/config/constants.dart';

class FoodRepository {
  final HttpUtil _httpUtil = HttpUtil();

  Future<List<Food>> getFoodList() async {
    final data = await _httpUtil.getList(AppConstants.foodsUrl);
    return data.map((json) => Food.fromJson(json)).toList();
  }

  Future<List<Food>> searchFoods(String keyword) async {
    final list = await getFoodList();
    if (keyword.isEmpty) return list;
    return list.where((food) =>
        food.name.toLowerCase().contains(keyword.toLowerCase())).toList();
  }
}