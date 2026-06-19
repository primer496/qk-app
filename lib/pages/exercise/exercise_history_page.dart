import 'package:flutter/material.dart';
import 'package:qk/models/exercise_record.dart';
import 'package:qk/services/exercise_service.dart';
import 'package:qk/widgets/common_app_bar.dart';
import 'package:qk/widgets/empty_state_widget.dart';
import 'package:qk/widgets/loading_widget.dart';

class ExerciseHistoryPage extends StatefulWidget {
  const ExerciseHistoryPage({super.key});

  @override
  State<ExerciseHistoryPage> createState() => _ExerciseHistoryPageState();
}

class _ExerciseHistoryPageState extends State<ExerciseHistoryPage> {
  final ExerciseService _exerciseService = ExerciseService();
  List<ExerciseRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      _records = await _exerciseService.getAllRecords();
      _records.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: ' + e.toString())),
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
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _exerciseService.deleteRecord(recordId);
      _loadRecords();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
      }
    }
  }

  String _formatDateTime(DateTime date) {
    return date.month.toString() +
        '月' +
        date.day.toString() +
        '日 ' +
        date.hour.toString() +
        ':' +
        date.minute.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(title: 'Exercise History'),
      body: _isLoading
          ? const LoadingWidget()
          : _records.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.fitness_center_outlined,
              message: 'No exercise records yet',
              actionLabel: 'Add Record',
            )
          : RefreshIndicator(
              onRefresh: _loadRecords,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final record = _records[index];
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
                          Icons.fitness_center,
                          color: Colors.orange,
                        ),
                      ),
                      title: Text(record.sportName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(_formatDateTime(record.date)),
                          Text(
                            record.durationMinutes.toString() +
                                'min - ' +
                                record.caloriesBurned.toStringAsFixed(1) +
                                'kcal',
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
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'exercise_history_add',
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/exercise/add',
          ).then((_) => _loadRecords());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
