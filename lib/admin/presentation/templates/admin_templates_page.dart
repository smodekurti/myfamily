import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_scaffold.dart';

class AdminTemplatesPage extends ConsumerStatefulWidget {
  const AdminTemplatesPage({super.key});

  @override
  ConsumerState<AdminTemplatesPage> createState() => _AdminTemplatesPageState();
}

class _AdminTemplatesPageState extends ConsumerState<AdminTemplatesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _templates = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await Supabase.instance.client
          .from('grocery_templates')
          .select()
          .order('name');

      if (mounted) {
        setState(() {
          _templates = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createTemplate(String name, String description) async {
    try {
      await Supabase.instance.client.from('grocery_templates').insert({
        'name': name,
        'description': description,
        // created_by is optional or can be null for system templates
      });
      _fetchTemplates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating template: $e')));
      }
    }
  }

  Future<void> _deleteTemplate(String id) async {
    try {
      await Supabase.instance.client
          .from('grocery_templates')
          .delete()
          .eq('id', id);
      _fetchTemplates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting template: $e')));
      }
    }
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _createTemplate(
                  nameController.text,
                  descriptionController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Grocery Templates',
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));

    if (_templates.isEmpty) {
      return const Center(child: Text('No templates found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_basket),
            title: Text(template['name'] as String),
            subtitle: Text(template['description'] as String? ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTemplate(template['id']),
            ),
            onTap: () {
              // Navigate to details to edit items
              context.go('/templates/${template['id']}');
            },
          ),
        );
      },
    );
  }
}
