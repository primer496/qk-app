import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../services/habit_storage_util.dart';

/// 习惯打卡主页
///
/// 展示当日完成进度、连续打卡天数，以及 5 种预设习惯的打卡列表。
/// 用户可通过右侧 Checkbox 快速切换打卡状态，数据实时写入 shared_preferences。
class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  // ── 今日习惯状态 Map<habitId, bool> ──
  Map<String, bool> _habitStatus = {};

  // ── 统计数字 ──
  int _doneCount = 0;
  int _streakDays = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 从本地存储加载今日习惯状态与统计信息
  Future<void> _loadData() async {
    final progress = await HabitStorageUtil.getTodayHabitProgress();
    setState(() {
      _habitStatus = Map<String, bool>.from(progress['status'] as Map);
      _doneCount = progress['doneCount'] as int;
      _streakDays = progress['streakDays'] as int;
      _isLoading = false;
    });
  }

  /// 切换某习惯的打卡状态
  Future<void> _onToggle(String habitId) async {
    final now = DateTime.now();
    final newState = await HabitStorageUtil.toggleHabit(habitId, now);

    setState(() {
      _habitStatus[habitId] = newState;
      _doneCount = _habitStatus.values.where((v) => v).length;
    });

    // 切换后重新计算连续天数（因为今天的状态可能影响 streak）
    final newStreak = await HabitStorageUtil.getStreakDays();
    setState(() {
      _streakDays = newStreak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = HabitStorageUtil.presetHabits.length;
    final percentage = total == 0 ? 0.0 : _doneCount / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯打卡'),
        actions: [
          // 周视图入口
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: '周打卡视图',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.habitWeekly),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  // ── 顶部进度卡片 ──
                  _buildProgressCard(theme, percentage, total),
                  const SizedBox(height: 16),
                  // ── 习惯列表 ──
                  ...HabitStorageUtil.presetHabits.map((habit) {
                    final id = habit['id']!;
                    final name = habit['name']!;
                    final icon = habit['icon']!;
                    final done = _habitStatus[id] ?? false;

                    return _buildHabitItem(theme, id, name, icon, done);
                  }),
                ],
              ),
            ),
    );
  }

  /// 顶部进度与连续天数卡片
  Widget _buildProgressCard(
    ThemeData theme,
    double percentage,
    int total,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('今日完成进度', style: theme.textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '连续 $_streakDays 天',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已完成 $_doneCount / $total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 单个习惯打卡项
  Widget _buildHabitItem(
    ThemeData theme,
    String habitId,
    String name,
    String icon,
    bool done,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: done ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onToggle(habitId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 习惯图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? theme.colorScheme.primary.withAlpha(200)
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 习惯名称
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: done
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      done ? '已完成' : '未完成',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: done
                            ? theme.colorScheme.onPrimaryContainer.withAlpha(180)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 打卡 Checkbox
              Checkbox(
                value: done,
                onChanged: (_) => _onToggle(habitId),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
