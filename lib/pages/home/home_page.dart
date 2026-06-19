import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../models/article.dart';
import '../../repository/article_repository.dart';
import '../../services/exercise_service.dart';
import '../../services/diet_service.dart';
import '../../services/habit_storage_util.dart';
import '../../services/storage_util.dart';
import '../profile/profile_change_notifier.dart';

/// 首页 — 今日健康数据概览（组长负责）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ExerciseService _exerciseService = ExerciseService();
  final DietService _dietService = DietService();

  final ArticleRepository _articleRepo = ArticleRepository();

  String _nickname = '用户';
  int _avatarIndex = 0;
  int _todayExerciseKcal = 0;
  int _todayDietKcal = 0;
  int _exerciseGoal = 30;
  int _dietGoal = 2000;

  static const List<IconData> _presetAvatars = [
    Icons.person,
    Icons.face,
    Icons.sentiment_satisfied_alt,
    Icons.pets,
    Icons.sports_soccer,
    Icons.music_note,
  ];

  static const List<Color> _avatarColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  // 习惯完成状态（从本地存储加载）
  Map<String, bool> _habitStatus = {};
  int _habitDoneCount = 0;

  // 今日推荐科普（远程加载）
  Article? _todayArticle;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    ExerciseService.changeNotifier.addListener(_loadUserData);
    DietService.changeNotifier.addListener(_loadUserData);
    HabitStorageUtil.changeNotifier.addListener(_loadUserData);
    ProfileChangeNotifier.changeNotifier.addListener(_loadUserData);
  }

  @override
  void dispose() {
    ExerciseService.changeNotifier.removeListener(_loadUserData);
    DietService.changeNotifier.removeListener(_loadUserData);
    HabitStorageUtil.changeNotifier.removeListener(_loadUserData);
    ProfileChangeNotifier.changeNotifier.removeListener(_loadUserData);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final exerciseCalories = await _exerciseService.getTodayCaloriesBurned();
      final dietCalories = await _dietService.getTodayCalories();
      final habitProgress = await HabitStorageUtil.getTodayHabitProgress();

      final nickname = StorageUtil().getString('profile_nickname');
      final avatarIndex = StorageUtil().getInt('profile_avatar_index');
      final exerciseGoal = StorageUtil().getInt('goal_exercise_duration');
      final dietGoal = StorageUtil().getInt('goal_calorie_intake');

      // 远程加载科普文章（取随机一篇）
      Article? article;
      try {
        final articles = await _articleRepo.getArticleList();
        if (articles.isNotEmpty) {
          article = articles[Random().nextInt(articles.length)];
        }
      } catch (_) {}

      setState(() {
        _nickname = nickname ?? '用户';
        _avatarIndex =
            avatarIndex != null &&
                avatarIndex >= 0 &&
                avatarIndex < _presetAvatars.length
            ? avatarIndex
            : 0;
        _todayExerciseKcal = exerciseCalories.round();
        _todayDietKcal = dietCalories.round();
        _exerciseGoal = exerciseGoal ?? 30;
        _dietGoal = dietGoal ?? 2000;
        _habitStatus = Map<String, bool>.from(habitProgress['status'] as Map);
        _habitDoneCount = habitProgress['doneCount'] as int;
        _todayArticle = article;
      });
    } catch (e) {
      setState(() {
        _nickname = '用户';
        _avatarIndex = 0;
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
            backgroundColor: _avatarColors[_avatarIndex].withOpacity(0.15),
            child: Icon(
              _presetAvatars[_avatarIndex],
              size: 32,
              color: _avatarColors[_avatarIndex],
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
    final habits = HabitStorageUtil.presetHabits;
    final doneCount = _habitDoneCount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.habit).then((_) {
            _loadUserData();
          });
        },
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
              LinearProgressIndicator(
                value: doneCount / habits.length,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(habits.length, (i) {
                  final done = _habitStatus[habits[i]['id']] ?? false;
                  return Column(
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
                  );
                }),
              ),
            ],
          ),
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
              goal: '目标 ${_exerciseGoal}min',
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
              goal: '目标 $_dietGoal kcal',
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
    String? goal,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (goal != null)
                  Text(
                    goal,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
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
    final article = _todayArticle;
    if (article == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: const EdgeInsets.only(top: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.knowledgeDetail,
            arguments: article,
          ),
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
                        article.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        article.publishTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
