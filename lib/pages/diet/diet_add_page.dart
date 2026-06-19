import 'package:flutter/material.dart';
import 'package:qk/config/routes.dart';
import 'package:qk/models/food.dart';
import 'package:qk/models/diet_record.dart';
import 'package:qk/services/diet_service.dart';
import 'package:qk/widgets/common_app_bar.dart';

/// 添加饮食记录页面
class DietAddPage extends StatefulWidget {
  const DietAddPage({super.key});

  @override
  State<DietAddPage> createState() => _DietAddPageState();
}

class _DietAddPageState extends State<DietAddPage> {
  final DietService _dietService = DietService();

  Food? _selectedFood;
  double _weightGrams = 100;
  String _mealType = '早餐';
  DateTime _selectedDate = DateTime.now();

  final List<String> _mealTypes = ['早餐', '午餐', '晚餐', '加餐'];

  Future<void> _selectFood() async {
    final result = await Navigator.pushNamed(context, AppRoutes.dietFoodSelect);
    if (result is Food) {
      setState(() => _selectedFood = result);
    }
  }

  double _calculateCalories() {
    if (_selectedFood == null) return 0;
    return (_selectedFood!.caloriesPer100g * _weightGrams) / 100;
  }

  Future<void> _saveRecord() async {
    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择食物')),
      );
      return;
    }

    final record = DietRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodId: _selectedFood!.id,
      foodName: _selectedFood!.name,
      foodCategory: _selectedFood!.category,
      caloriesPer100g: _selectedFood!.caloriesPer100g,
      weightGrams: _weightGrams,
      totalCalories: _calculateCalories(),
      mealType: _mealType,
      date: _selectedDate,
    );

    await _dietService.addRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录保存成功')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(title: '添加饮食记录'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择食物',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectFood,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _selectedFood != null
                              ? Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFood!.name,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_selectedFood!.category} · ${_selectedFood!.caloriesPer100g} kcal/100g',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Expanded(
                                  child: Text(
                                    '点击选择食物',
                                    style: TextStyle(color: Colors.grey),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '食用重量',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _weightGrams > 10
                            ? () => setState(() => _weightGrams -= 10)
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          '${_weightGrams.toStringAsFixed(0)} 克',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _weightGrams < 5000
                            ? () => setState(() => _weightGrams += 10)
                            : null,
                      ),
                    ],
                  ),
                  Slider(
                    value: _weightGrams,
                    min: 10,
                    max: 1000,
                    divisions: 99,
                    onChanged: (value) {
                      setState(() => _weightGrams = value);
                    },
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '餐次类型',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _mealTypes.map((type) => ElevatedButton(
                          onPressed: () {
                            setState(() => _mealType = type);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mealType == type
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: _mealType == type
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                          child: Text(type),
                        )).toList(),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择日期',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _showDatePicker,
                    child: Row(
                      children: [
                        Text(_formatDate(_selectedDate)),
                        const Spacer(),
                        Icon(
                          Icons.calendar_month_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '预计摄入热量',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFood != null
                        ? '${_calculateCalories().toStringAsFixed(1)} kcal'
                        : '请先选择食物',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveRecord,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('保存记录'),
          ),
        ],
      ),
    );
  }
}