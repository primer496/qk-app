import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'pages/home/home_page.dart';
import 'pages/exercise/exercise_page.dart';
import 'pages/exercise/exercise_add_page.dart';
import 'pages/exercise/exercise_history_page.dart';
import 'pages/exercise/exercise_stats_page.dart';
import 'pages/diet/diet_page.dart';
import 'pages/diet/diet_add_page.dart';
import 'pages/diet/diet_food_select_page.dart';
import 'pages/diet/diet_today_page.dart';
import 'pages/diet/diet_stats_page.dart';
import 'pages/habit/habit_placeholder.dart';
import 'pages/knowledge/knowledge_placeholder.dart';
import 'pages/profile/profile_placeholder.dart';

/// MaterialApp 配置
class QkApp extends StatelessWidget {
  const QkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '轻康',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  /// 路由工厂
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // 使用 Map 匹配路由
    final routes = <String, WidgetBuilder>{
      // ── 首页（底部导航壳） ──
      AppRoutes.home: (_) => const MainShell(),

      // ── 运动打卡（角色4） ──
      AppRoutes.exerciseAdd: (_) => const ExerciseAddPage(),
      AppRoutes.exerciseHistory: (_) => const ExerciseHistoryPage(),
      AppRoutes.exerciseStats: (_) => const ExerciseStatsPage(),

      // ── 饮食记录（角色5） ──
      AppRoutes.dietAdd: (_) => const DietAddPage(),
      AppRoutes.dietFoodSelect: (_) => const DietFoodSelectPage(),
      AppRoutes.dietToday: (_) => const DietTodayPage(),
      AppRoutes.dietStats: (_) => const DietStatsPage(),

      // ── 习惯打卡（角色6） ──
      AppRoutes.habit: (_) => const HabitPlaceholder(title: '习惯打卡'),
      AppRoutes.habitWeekly: (_) => const HabitPlaceholder(title: '周打卡视图'),

      // ── 健康科普（角色6） ──
      AppRoutes.knowledgeList: (_) => const KnowledgePlaceholder(title: '健康科普'),
      AppRoutes.knowledgeDetail: (_) =>
          const KnowledgePlaceholder(title: '文章详情'),

      // ── 个人中心（角色3） ──
      AppRoutes.profile: (_) => const ProfilePlaceholder(title: '个人中心'),
      AppRoutes.profileNickname: (_) => const ProfilePlaceholder(title: '昵称设置'),
      AppRoutes.profileGoal: (_) => const ProfilePlaceholder(title: '健康目标'),
      AppRoutes.profileSettings: (_) => const ProfilePlaceholder(title: '设置'),
    };

    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    // 未匹配路由，回退到首页
    return MaterialPageRoute(
      builder: (_) => const MainShell(),
      settings: settings,
    );
  }
}

/// 底部导航栏外壳
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // 底部5个Tab对应的页面
  final List<Widget> _pages = const [
    HomePage(),
    ExercisePage(),
    DietPage(),
    HabitPlaceholder(title: '习惯打卡'),
    ProfilePlaceholder(title: '个人中心'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '首页'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_rounded),
            label: '运动',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_rounded),
            label: '饮食',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_rounded),
            label: '习惯',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
