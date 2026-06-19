import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../services/exercise_service.dart';
import '../../services/diet_service.dart';

/// 首页 — 今日健康数据概览（组长负责）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ExerciseService _exerciseService = ExerciseService();
  final DietService _dietService = DietService();
  
  String _nickname = '用户';
  int _todayExerciseKcal = 0;
  int _todayDietKcal = 0;

  // 习惯完成状态（mock）
  final List<bool> _habitDone = [true, true, false, true, false];

  // 今日推荐科普（mock）
  final Map<String, String> _todayArticle = {
    'title': '每天走多少步最健康？',
    'summary': '世界卫生组织建议成年人每天至少进行……',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final exerciseCalories = await _exerciseService.getTodayCaloriesBurned();
      final dietCalories = await _dietService.getTodayCalories();
      setState(() {
        _nickname = '用户';
        _todayExerciseKcal = exerciseCalories.round();
        _todayDietKcal = dietCalories.round();
      });
    } catch (e) {
      setState(() {
        _nickname = '用户';
        _todayExerciseKcal = 0;
        _todayDietKcal = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ── 1. 问候区 ──
            _buildGreeting(theme),
            const SizedBox(height: 8),

            // ── 2. 习惯打卡进度 ──
            _buildHabitProgress(theme),
            const SizedBox(height: 8),

            // ── 3. 卡路里概览卡片 ──
            _buildCalorieOverview(theme),
            const SizedBox(height: 8),

            // ── 4. 快捷功能入口 ──
            _buildQuickActions(theme),
            const SizedBox(height: 8),

            // ── 5. 今日科普推荐 ──
            _buildArticleCard(theme),
          ],
        ),
      ),
    );
  }

  // ─── 1. 问候区 ───
  Widget _buildGreeting(ThemeData theme) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = '早上好';
    } else if (hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 32,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          // 问候文字
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting，$_nickname',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(DateTime.now()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. 习惯打卡进度 ───
  Widget _buildHabitProgress(ThemeData theme) {
    final habits = AppConstants.presetHabits;
    final doneCount = _habitDone.where((d) => d).length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('今日习惯', style: theme.textTheme.titleSmall),
                Text(
                  '$doneCount / ${habits.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 进度条
            LinearProgressIndicator(
              value: doneCount / habits.length,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            // 习惯图标行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(habits.length, (i) {
                final done = _habitDone[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.habit),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Center(
                          child: Text(
                            habits[i]['icon']!,
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        habits[i]['name']!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: done
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. 卡路里概览 ───
  Widget _buildCalorieOverview(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 运动消耗
          Expanded(
            child: _buildKcalCard(
              theme,
              icon: Icons.local_fire_department,
              iconColor: Colors.orange,
              label: '运动消耗',
              value: '$_todayExerciseKcal',
              unit: 'kcal',
            ),
          ),
          const SizedBox(width: 12),
          // 饮食摄入
          Expanded(
            child: _buildKcalCard(
              theme,
              icon: Icons.restaurant,
              iconColor: Colors.teal,
              label: '饮食摄入',
              value: '$_todayDietKcal',
              unit: 'kcal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKcalCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. 快捷功能入口 ───
  Widget _buildQuickActions(ThemeData theme) {
    final actions = [
      {
        'icon': Icons.fitness_center,
        'label': '添加运动',
        'route': AppRoutes.exerciseAdd,
      },
      {
        'icon': Icons.restaurant_menu,
        'label': '添加饮食',
        'route': AppRoutes.dietAdd,
      },
      {
        'icon': Icons.check_circle_outline,
        'label': '习惯打卡',
        'route': AppRoutes.habit,
      },
      {
        'icon': Icons.menu_book,
        'label': '健康科普',
        'route': AppRoutes.knowledgeList,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final a = actions[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, a['route'] as String),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    a['icon'] as IconData,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  a['label'] as String,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── 5. 今日科普推荐 ───
  Widget _buildArticleCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: const EdgeInsets.only(top: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(context, AppRoutes.knowledgeDetail),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日推荐',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _todayArticle['title']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _todayArticle['summary']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 工具方法 ───
  String _formatDate(DateTime date) {
    final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${date.year}年${date.month}月${date.day}日 星期${weekDays[date.weekday - 1]}';
  }
}
