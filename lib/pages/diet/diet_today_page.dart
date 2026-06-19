import 'package:flutter/material.dart';
import 'package:qk/config/routes.dart';
import 'package:qk/models/diet_record.dart';
import 'package:qk/services/diet_service.dart';
import 'package:qk/widgets/common_app_bar.dart';
import 'package:qk/widgets/empty_state_widget.dart';
import 'package:qk/widgets/loading_widget.dart';

/// 今日饮食记录页面
class DietTodayPage extends StatefulWidget {
  const DietTodayPage({super.key});

  @override
  State<DietTodayPage> createState() => _DietTodayPageState();
}

class _DietTodayPageState extends State<DietTodayPage> {
  final DietService _dietService = DietService();
  Map<String, List<DietRecord>> _recordsByMeal = {};
  double _totalCalories = 0;
  bool _isLoading = true;

  final List<String> _mealOrder = ['早餐', '午餐', '晚餐', '加餐'];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final todayRecords = await _dietService.getRecordsByDate(DateTime.now());
      final grouped = <String, List<DietRecord>>{};
      for (final record in todayRecords) {
        grouped[record.mealType] = (grouped[record.mealType] ?? [])..add(record);
      }
      setState(() {
        _recordsByMeal = grouped;
        _totalCalories = todayRecords.fold(0.0, (sum, r) => sum + r.totalCalories);
      });
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

  Future<void> _deleteRecord(String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条饮食记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dietService.deleteRecord(recordId);
      _loadRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  double _getMealCalories(List<DietRecord> records) {
    return records.fold(0.0, (sum, r) => sum + r.totalCalories);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(title: '今日饮食'),
      body: _isLoading
          ? const LoadingWidget()
          : _recordsByMeal.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.restaurant_outlined,
                  message: '今天还没有饮食记录',
                  actionLabel: '添加记录',
                  onAction: () {
                    Navigator.pushNamed(context, AppRoutes.dietAdd)
                        .then((_) => _loadRecords());
                  },
                )
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                '今日总摄入',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_totalCalories.toStringAsFixed(0)}',
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
                      ..._mealOrder.where((meal) => _recordsByMeal.containsKey(meal)).map((meal) {
                        final records = _recordsByMeal[meal]!;
                        final mealCalories = _getMealCalories(records);
                        return Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  meal,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${mealCalories.toStringAsFixed(0)} kcal',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...records.map((record) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    title: Text(record.foodName),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          '${record.weightGrams.toStringAsFixed(0)}克 · ${record.foodCategory}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '${_formatTime(record.date)} · ${record.totalCalories.toStringAsFixed(1)}kcal',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: theme.colorScheme.error,
                                      onPressed: () => _deleteRecord(record.id),
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.dietAdd)
              .then((_) => _loadRecords());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}