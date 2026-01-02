import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyTasksTab extends StatefulWidget {
  final String familyId;

  const FamilyTasksTab({super.key, required this.familyId});

  @override
  State<FamilyTasksTab> createState() => _FamilyTasksTabState();
}

class _FamilyTasksTabState extends State<FamilyTasksTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      setState(() => _isLoading = true);
      // Fetch tasks (simple, no joins for now to minimize complexity)
      final response = await Supabase.instance.client
          .from('tasks')
          .select()
          .eq('family_id', widget.familyId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show error
      }
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      await Supabase.instance.client.from('tasks').delete().eq('id', id);
      _fetchTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_tasks.isEmpty) return const Center(child: Text('No tasks found.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final isCompleted = task['status'] == 'completed';

        return Card(
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            title: Text(
              task['title'] ?? 'Untitled',
              style: TextStyle(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(task['description'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () => _deleteTask(task['id']),
            ),
          ),
        );
      },
    );
  }
}
