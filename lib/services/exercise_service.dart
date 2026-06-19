import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:qk/models/exercise_record.dart';
import 'package:qk/services/storage_util.dart';

class ExerciseService {
  static const String _storageKey = 'exercise_records';
  final StorageUtil _storage = StorageUtil();

  /// 数据变更通知器，增删记录后 +1，页面监听此值自动刷新
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  Future<List<ExerciseRecord>> getAllRecords() async {
    final jsonList = _storage.getStringList(_storageKey);
    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }
    return jsonList
        .map((json) => ExerciseRecord.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<List<ExerciseRecord>> getRecordsByDate(DateTime date) async {
    final allRecords = await getAllRecords();
    final targetDate = DateTime(date.year, date.month, date.day);
    return allRecords.where((record) {
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      return recordDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  Future<void> addRecord(ExerciseRecord record) async {
    final allRecords = await getAllRecords();
    allRecords.add(record);
    await _saveAllRecords(allRecords);
    changeNotifier.value++;
  }

  Future<void> deleteRecord(String recordId) async {
    final allRecords = await getAllRecords();
    allRecords.removeWhere((r) => r.id == recordId);
    await _saveAllRecords(allRecords);
    changeNotifier.value++;
  }

  Future<void> _saveAllRecords(List<ExerciseRecord> records) async {
    final jsonList = records.map((r) => jsonEncode(r.toJson())).toList();
    await _storage.saveStringList(_storageKey, jsonList);
  }

  Future<double> getTodayCaloriesBurned() async {
    final todayRecords = await getRecordsByDate(DateTime.now());
    double total = 0;
    for (final record in todayRecords) {
      total += record.caloriesBurned;
    }
    return total;
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
        weeklyData[dateStr] =
            (weeklyData[dateStr] ?? 0) + record.caloriesBurned;
      }
    }

    return weeklyData;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
