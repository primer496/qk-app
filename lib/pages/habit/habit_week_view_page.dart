import 'package:flutter/material.dart';
import '../../services/habit_storage_util.dart';

/// 周打卡视图页
///
/// 用网格矩阵直观展示最近 7 天（含今天）5 种预设习惯的完成情况。
/// 完成的方块显示主题色，未完成显示灰色，帮助用户一目了然地回顾本周表现。
class HabitWeekViewPage extends StatefulWidget {
  const HabitWeekViewPage({super.key});

  @override
  State<HabitWeekViewPage> createState() => _HabitWeekViewPageState();
}

class _HabitWeekViewPageState extends State<HabitWeekViewPage> {
  // ── 最近 7 天数据 ──
  /// 每个元素结构：`{ 'date': DateTime, 'doneMap': Map<String, bool>, 'doneCount': int }`
  List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  /// 加载最近 7 天打卡矩阵
  Future<void> _loadWeekData() async {
    final data = await HabitStorageUtil.getRecentDaysMatrix(7);
    setState(() {
      _days = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周打卡视图'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeekData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── 本周统计概览 ──
                  _buildWeekSummary(theme),
                  const SizedBox(height: 24),
                  // ── 打卡矩阵 ──
                  _buildWeekMatrix(theme),
                ],
              ),
            ),
    );
  }

  /// 本周统计概览卡片
  Widget _buildWeekSummary(ThemeData theme) {
    // 计算本周总完成数 / 总习惯数
    int totalDone = 0;
    int totalHabits = HabitStorageUtil.presetHabits.length * _days.length;
    for (final day in _days) {
      totalDone += (day['doneCount'] as int);
    }
    final weekRate = totalHabits == 0 ? 0.0 : totalDone / totalHabits;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.date_range_rounded,
                color: theme.colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本周完成率',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(weekRate * 100).toInt()}%',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '共完成 $totalDone / $totalHabits 项习惯',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 周打卡矩阵主体
  Widget _buildWeekMatrix(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '近7天打卡矩阵',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // ── 日期标题行 ──
            _buildDateHeader(theme),
            const SizedBox(height: 12),
            // ── 每个习惯的行 ──
            ...HabitStorageUtil.presetHabits.map((habit) {
              final id = habit['id']!;
              final name = habit['name']!;
              final icon = habit['icon']!;
              return _buildHabitRow(theme, id, name, icon);
            }),
          ],
        ),
      ),
    );
  }

  /// 日期标题行（7 天）
  Widget _buildDateHeader(ThemeData theme) {
    return Row(
      children: [
        // 左侧占位（与习惯名称列对齐）
        const SizedBox(width: 72),
        // 7 个日期
        ..._days.map((day) {
          final date = day['date'] as DateTime;
          final isToday = _isToday(date);
          return Expanded(
            child: Column(
              children: [
                Text(
                  _weekdayLabel(date.weekday),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isToday ? '今天' : '${date.month}/${date.day}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 单个习惯行（左侧名称 + 右侧 7 个状态方块）
  Widget _buildHabitRow(
    ThemeData theme,
    String habitId,
    String name,
    String icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 左侧：图标 + 名称
          SizedBox(
            width: 72,
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // 右侧：7 天方块
          ..._days.map((day) {
            final doneMap = day['doneMap'] as Map<String, bool>;
            final done = doneMap[habitId] ?? false;
            return Expanded(
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: done
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 工具方法 ──

  /// 判断是否为今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 星期数字转中文标签
  String _weekdayLabel(int weekday) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${labels[weekday - 1]}';
  }
}
