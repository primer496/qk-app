import 'package:shared_preferences/shared_preferences.dart';

/// 习惯打卡本地存储工具类
///
/// 封装 shared_preferences 的读写逻辑，提供习惯打卡状态的持久化、
/// 当日进度统计及连续打卡天数计算能力。
class HabitStorageUtil {
  HabitStorageUtil._();

  // ═══════════════════════════════════════════════════════════
  // 1. 预设习惯配置（与 AppConstants.presetHabits 保持一致）
  // ═══════════════════════════════════════════════════════════

  /// 5 种预设习惯列表
  static const List<Map<String, String>> presetHabits = [
    {'id': 'drink_water', 'name': '喝水8杯', 'icon': '💧'},
    {'id': 'early_sleep', 'name': '早睡', 'icon': '🌙'},
    {'id': 'early_rise', 'name': '早起', 'icon': '🌅'},
    {'id': 'exercise', 'name': '运动', 'icon': '🏃'},
    {'id': 'breakfast', 'name': '吃早餐', 'icon': '🍳'},
  ];

  // ═══════════════════════════════════════════════════════════
  // 2. Key 生成规则
  // ═══════════════════════════════════════════════════════════

  /// 生成某 habit 在某日期的存储 key
  /// 格式：`habit_done_<habitId>_<yyyyMMdd>`
  static String _key(String habitId, DateTime date) {
    final d = _normalize(date);
    return 'habit_done_${habitId}_${d.year}${_two(d.month)}${_two(d.day)}';
  }

  /// 日期标准化（去除时分秒，仅保留年月日）
  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  // ═══════════════════════════════════════════════════════════
  // 3. 核心读写方法
  // ═══════════════════════════════════════════════════════════

  /// 切换（保存/取消）某项习惯在指定日期的打卡状态
  ///
  /// [habitId] 习惯唯一标识
  /// [date]    目标日期（自动抹除时分秒）
  /// 返回切换后的新状态
  static Future<bool> toggleHabit(String habitId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(habitId, date);
    final current = prefs.getBool(key) ?? false;
    final next = !current;
    await prefs.setBool(key, next);
    return next;
  }

  /// 设置某项习惯在指定日期的打卡状态（显式设置）
  static Future<void> setHabitDone(
    String habitId,
    DateTime date,
    bool done,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(habitId, date), done);
  }

  /// 查询某项习惯在指定日期是否已完成打卡
  static Future<bool> isHabitDone(String habitId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(habitId, date)) ?? false;
  }

  // ═══════════════════════════════════════════════════════════
  // 4. 批量 / 统计方法
  // ═══════════════════════════════════════════════════════════

  /// 获取指定日期所有习惯的完成状态
  ///
  /// 返回 `Map<habitId, bool>`，key 顺序与 [presetHabits] 一致
  static Future<Map<String, bool>> getAllHabitsStatus(DateTime date) async {
    final result = <String, bool>{};
    for (final h in presetHabits) {
      final id = h['id']!;
      result[id] = await isHabitDone(id, date);
    }
    return result;
  }

  /// 获取当日完成进度
  ///
  /// 返回 Map 包含：
  /// - doneCount   : 已完成习惯数
  /// - totalCount  : 习惯总数（固定 5）
  /// - percentage  : 完成百分比（0.0 ~ 1.0）
  /// - streakDays  : 当前连续打卡天数
  ///
  /// 供首页 [HomePage] 调用展示进度卡片。
  static Future<Map<String, dynamic>> getTodayHabitProgress() async {
    final today = _normalize(DateTime.now());
    final status = await getAllHabitsStatus(today);
    final doneCount = status.values.where((v) => v).length;
    final totalCount = presetHabits.length;
    final percentage = totalCount == 0 ? 0.0 : doneCount / totalCount;
    final streakDays = await getStreakDays();

    return {
      'doneCount': doneCount,
      'totalCount': totalCount,
      'percentage': percentage,
      'streakDays': streakDays,
      'status': status,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // 5. 连续打卡天数计算
  // ═══════════════════════════════════════════════════════════

  /// 计算连续打卡天数
  ///
  /// 逻辑说明：
  /// 1. 从 [baseDate]（默认今天）开始，往前逐天检查；
  /// 2. 若某天至少完成了 **1 个**习惯，则视为该日已打卡，streak + 1；
  /// 3. 若某天没有任何习惯完成，则连续中断，立即返回当前 streak；
  /// 4. 因此，如果昨天没打卡，今天的连续天数会重置为 0（今天也没打）或 1（今天打了）。
  static Future<int> getStreakDays({DateTime? baseDate}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _normalize(baseDate ?? DateTime.now());
    int streak = 0;

    // 从 baseDate 开始往前推，检查每一天是否至少完成 1 个习惯
    for (int i = 0; i < 365; i++) {
      final checkDay = today.subtract(Duration(days: i));
      bool anyDone = false;

      for (final h in presetHabits) {
        final key = _key(h['id']!, checkDay);
        if (prefs.getBool(key) ?? false) {
          anyDone = true;
          break;
        }
      }

      if (anyDone) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ═══════════════════════════════════════════════════════════
  // 6. 辅助：最近 N 天数据（供周视图页使用）
  // ═══════════════════════════════════════════════════════════

  /// 获取最近 [days] 天（包含今天）的打卡矩阵
  ///
  /// 返回 `List<Map<String, dynamic>>`，每个元素代表一天：
  /// - date      : DateTime（已标准化）
  /// - doneMap   : `Map<habitId, bool>`
  /// - doneCount : 当日完成习惯数
  ///
  /// 列表按日期 **升序** 排列（最早在前，今天在后）。
  static Future<List<Map<String, dynamic>>> getRecentDaysMatrix(
    int days,
  ) async {
    final today = _normalize(DateTime.now());
    final result = <Map<String, dynamic>>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final doneMap = await getAllHabitsStatus(date);
      final doneCount = doneMap.values.where((v) => v).length;

      result.add({
        'date': date,
        'doneMap': doneMap,
        'doneCount': doneCount,
      });
    }

    return result;
  }
}
