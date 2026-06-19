import 'package:flutter/material.dart';
import 'package:qk/config/routes.dart';
import 'package:qk/services/exercise_service.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final ExerciseService _exerciseService = ExerciseService();
  double _todayCalories = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
    ExerciseService.changeNotifier.addListener(_loadTodayData);
  }

  @override
  void dispose() {
    ExerciseService.changeNotifier.removeListener(_loadTodayData);
    super.dispose();
  }

  Future<void> _loadTodayData() async {
    final calories = await _exerciseService.getTodayCaloriesBurned();
    setState(() => _todayCalories = calories);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('运动打卡'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '今日运动消耗',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _todayCalories.toStringAsFixed(0),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              final items = [
                {
                  'icon': Icons.add_circle_outline,
                  'title': '添加记录',
                  'subtitle': '记录运动时长',
                  'route': AppRoutes.exerciseAdd,
                  'color': theme.colorScheme.primary,
                },
                {
                  'icon': Icons.history_outlined,
                  'title': '运动历史',
                  'subtitle': '查看所有记录',
                  'route': AppRoutes.exerciseHistory,
                  'color': theme.colorScheme.secondary,
                },
                {
                  'icon': Icons.bar_chart_outlined,
                  'title': '统计分析',
                  'subtitle': '近7天数据',
                  'route': AppRoutes.exerciseStats,
                  'color': theme.colorScheme.tertiary,
                },
              ];
              final item = items[index];
              return Card(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      item['route'] as String,
                    ).then((_) => _loadTodayData());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '运动小贴士',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ' 每周至少进行150分钟中等强度有氧运动',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ' 运动前后记得热身和拉伸',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ' 保持规律运动比偶尔高强度运动更有效',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'exercise_add',
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.exerciseAdd,
          ).then((_) => _loadTodayData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
