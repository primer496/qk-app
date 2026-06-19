import 'package:flutter/material.dart';
import 'package:qk/models/sport.dart';
import 'package:qk/models/exercise_record.dart';
import 'package:qk/repository/sport_repository.dart';
import 'package:qk/services/exercise_service.dart';
import 'package:qk/widgets/common_app_bar.dart';
import 'package:qk/widgets/loading_widget.dart';

class ExerciseAddPage extends StatefulWidget {
  const ExerciseAddPage({super.key});

  @override
  State<ExerciseAddPage> createState() => _ExerciseAddPageState();
}

class _ExerciseAddPageState extends State<ExerciseAddPage> {
  final SportRepository _sportRepo = SportRepository();
  final ExerciseService _exerciseService = ExerciseService();
  
  List<Sport> _sports = [];
  bool _isLoading = true;
  Sport? _selectedSport;
  int _durationMinutes = 30;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSports();
  }

  Future<void> _loadSports() async {
    setState(() => _isLoading = true);
    try {
      _sports = await _sportRepo.getSportList();
      if (_sports.isNotEmpty) {
        _selectedSport = _sports[0];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load error: ' + e.toString())),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecord() async {
    if (_selectedSport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select sport type')),
      );
      return;
    }

    final caloriesBurned = (_selectedSport!.caloriesPerHour * _durationMinutes) / 60;
    final record = ExerciseRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sportId: _selectedSport!.id,
      sportName: _selectedSport!.name,
      durationMinutes: _durationMinutes,
      caloriesBurned: caloriesBurned,
      date: _selectedDate,
    );

    await _exerciseService.addRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record saved successfully')),
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
    return date.year.toString() + '年' + date.month.toString() + '月' + date.day.toString() + '日';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(title: 'Add Exercise Record'),
      body: _isLoading
          ? const LoadingWidget()
          : ListView(
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
                          'Select Sport Type',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<Sport>(
                            value: _selectedSport,
                            isExpanded: true,
                            underline: const SizedBox(),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                            ),
                            items: _sports.map((sport) {
                              return DropdownMenuItem(
                                value: sport,
                                child: Text(sport.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedSport = value);
                            },
                          ),
                        ),
                        if (_selectedSport != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Burns: ' + _selectedSport!.caloriesPerHour.toString() + ' kcal/hour',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
                          'Duration',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _durationMinutes > 5
                                  ? () => setState(() => _durationMinutes -= 5)
                                  : null,
                            ),
                            Expanded(
                              child: Text(
                                _durationMinutes.toString() + ' minutes',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: _durationMinutes < 180
                                  ? () => setState(() => _durationMinutes += 5)
                                  : null,
                            ),
                          ],
                        ),
                        Slider(
                          value: _durationMinutes.toDouble(),
                          min: 5,
                          max: 180,
                          divisions: 35,
                          onChanged: (value) {
                            setState(() => _durationMinutes = value.toInt());
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
                          'Select Date',
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
                          'Estimated Calories Burned',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedSport != null
                              ? ((_selectedSport!.caloriesPerHour * _durationMinutes) / 60).toStringAsFixed(1) + ' kcal'
                              : 'Please select sport type',
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
                  child: const Text('Save Record'),
                ),
              ],
            ),
    );
  }
}