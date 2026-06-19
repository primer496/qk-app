import 'dart:convert';
import 'package:qk/models/diet_record.dart';
import 'package:qk/services/storage_util.dart';

/// 饮食记录业务服务层
class DietService {
  static const String _storageKey = 'diet_records';
  final StorageUtil _storage = StorageUtil();

  Future<List<DietRecord>> getAllRecords() async {
    final jsonList = _storage.getStringList(_storageKey);
    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }
    return jsonList.map((json) => DietRecord.fromJson(jsonDecode(json))).toList();
  }

  Future<List<DietRecord>> getRecordsByDate(DateTime date) async {
    final allRecords = await getAllRecords();
    final targetDate = DateTime(date.year, date.month, date.day);
    return allRecords.where((record) {
      final recordDate = DateTime(record.date.year, record.date.month, record.date.day);
      return recordDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  Future<List<DietRecord>> getRecordsByMealType(DateTime date, String mealType) async {
    final dayRecords = await getRecordsByDate(date);
    return dayRecords.where((r) => r.mealType == mealType).toList();
  }

  Future<void> addRecord(DietRecord record) async {
    final allRecords = await getAllRecords();
    allRecords.add(record);
    await _saveAllRecords(allRecords);
  }

  Future<void> deleteRecord(String recordId) async {
    final allRecords = await getAllRecords();
    allRecords.removeWhere((r) => r.id == recordId);
    await _saveAllRecords(allRecords);
  }

  Future<void> _saveAllRecords(List<DietRecord> records) async {
    final jsonList = records.map((r) => jsonEncode(r.toJson())).toList();
    await _storage.saveStringList(_storageKey, jsonList);
  }

  Future<double> getTodayCalories() async {
    final todayRecords = await getRecordsByDate(DateTime.now());
    double total = 0;
    for (final record in todayRecords) {
      total += record.totalCalories;
    }
    return total;
  }

  Future<double> getCaloriesByDate(DateTime date) async {
    final records = await getRecordsByDate(date);
    return records.fold<double>(0.0, (sum, r) => sum + r.totalCalories);
  }

  Future<Map<String, double>> getWeeklyCalories() async {
    final allRecords = await getAllRecords();
    final weeklyData = <String, double>{};

    for (var i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = _formatDate(date);
      weeklyData[dateStr] = 0;
    }

    for (final record in allRecords) {
      final dateStr = _formatDate(record.date);
      if (weeklyData.containsKey(dateStr)) {
        weeklyData[dateStr] = (weeklyData[dateStr] ?? 0) + record.totalCalories;
      }
    }

    return weeklyData;
  }

  Future<Map<String, double>> getTodayCaloriesByMeal() async {
    final todayRecords = await getRecordsByDate(DateTime.now());
    final mealData = <String, double>{
      '早餐': 0,
      '午餐': 0,
      '晚餐': 0,
      '加餐': 0,
    };

    for (final record in todayRecords) {
      mealData[record.mealType] = (mealData[record.mealType] ?? 0) + record.totalCalories;
    }

    return mealData;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}