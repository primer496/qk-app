import 'package:flutter/material.dart';
import 'package:qk/models/food.dart';
import 'package:qk/repository/food_repository.dart';
import 'package:qk/widgets/common_app_bar.dart';
import 'package:qk/widgets/loading_widget.dart';
import 'package:qk/widgets/empty_state_widget.dart';

/// 食物选择页面
class DietFoodSelectPage extends StatefulWidget {
  const DietFoodSelectPage({super.key});

  @override
  State<DietFoodSelectPage> createState() => _DietFoodSelectPageState();
}

class _DietFoodSelectPageState extends State<DietFoodSelectPage> {
  final FoodRepository _foodRepo = FoodRepository();
  List<Food> _foods = [];
  List<Food> _filteredFoods = [];
  bool _isLoading = true;
  String _searchKeyword = '';
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoading = true);
    try {
      _foods = await _foodRepo.getFoodList();
      _categories = _foods.map((f) => f.category).toSet().toList();
      _filteredFoods = _foods;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载食物数据失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterFoods() {
    List<Food> result = _foods;
    if (_searchKeyword.isNotEmpty) {
      result = result.where((food) =>
          food.name.toLowerCase().contains(_searchKeyword.toLowerCase())).toList();
    }
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      result = result.where((food) => food.category == _selectedCategory).toList();
    }
    setState(() => _filteredFoods = result);
  }

  void _selectFood(Food food) {
    Navigator.pop(context, food);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(title: '选择食物'),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜索食物...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchKeyword = value;
                        _filterFoods();
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('全部'),
                          selected: _selectedCategory == null,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = null;
                              _filterFoods();
                            });
                          },
                        ),
                      ),
                      ..._categories.map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = _selectedCategory == category
                                      ? null
                                      : category;
                                  _filterFoods();
                                });
                              },
                            ),
                          )),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredFoods.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.food_bank_outlined,
                          message: '没有找到匹配的食物',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFoods,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredFoods.length,
                            itemBuilder: (context, index) {
                              final food = _filteredFoods[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.restaurant_outlined,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  title: Text(food.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        food.category,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        '${food.caloriesPer100g} kcal/100g',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _selectFood(food),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}