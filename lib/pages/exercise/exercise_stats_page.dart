import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qk/services/exercise_service.dart';
import 'package:qk/widgets/common_app_bar.dart';
import 'package:qk/widgets/loading_widget.dart';

class ExerciseStatsPage extends StatefulWidget {
  const ExerciseStatsPage({super.key});

  @override
  State<ExerciseStatsPage> createState() => _ExerciseStatsPageState();
}

class _ExerciseStatsPageState extends State<ExerciseStatsPage> {
  final ExerciseService _exerciseService = ExerciseService();
  Map<String, double> _weeklyData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    setState(() => _isLoading = true);
    try {
      _weeklyData = await _exerciseService.getWeeklyCalories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _getMaxValue() {
    if (_weeklyData.isEmpty) return 100;
    final max = _weeklyData.values.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max * 1.2 : 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = _weeklyData.keys.toList();
    final values = _weeklyData.values.toList();
    final totalCalories = _weeklyData.values.fold(0.0, (sum, val) => sum + val);

    return Scaffold(
      appBar: CommonAppBar(title: '运动统计'),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _loadWeeklyData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '近7天运动消耗',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipPadding: const EdgeInsets.all(8),
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${rod.toY.round()} kcal',
                                        TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          backgroundColor: theme.colorScheme.primary,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < keys.length) {
                                          return Text(
                                            keys[index],
                                            style: theme.textTheme.labelSmall,
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}',
                                          style: theme.textTheme.labelSmall,
                                        );
                                      },
                                      interval: _getMaxValue() / 4,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: _getMaxValue() / 4,
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(values.length, (index) {
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: values[index],
                                        color: theme.colorScheme.primary,
                                        width: 32,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '本周总消耗',
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                '${totalCalories.toStringAsFixed(0)} kcal',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '日均消耗',
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                '${(totalCalories / 7).toStringAsFixed(0)} kcal',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}