import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminTemplateDetailPage extends ConsumerStatefulWidget {
  final String templateId;

  const AdminTemplateDetailPage({super.key, required this.templateId});

  @override
  ConsumerState<AdminTemplateDetailPage> createState() =>
      _AdminTemplateDetailPageState();
}

class _AdminTemplateDetailPageState
    extends ConsumerState<AdminTemplateDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _template;
  List<Map<String, dynamic>> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch Template
      final tmplResponse = await Supabase.instance.client
          .from('grocery_templates')
          .select()
          .eq('id', widget.templateId)
          .single();

      // Fetch Items
      final itemsResponse = await Supabase.instance.client
          .from('grocery_template_items')
          .select()
          .eq('template_id', widget.templateId)
          .order('category')
          .order('name');

      if (mounted) {
        setState(() {
          _template = tmplResponse;
          _items = List<Map<String, dynamic>>.from(itemsResponse);
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

  Future<void> _addItem(
    String name,
    String category,
    double qty,
    String unit,
  ) async {
    try {
      await Supabase.instance.client.from('grocery_template_items').insert({
        'template_id': widget.templateId,
        'name': name,
        'category': category,
        'default_qty': qty,
        'unit': unit,
      });
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding item: $e')));
      }
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      await Supabase.instance.client
          .from('grocery_template_items')
          .delete()
          .eq('id', id);
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
      }
    }
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController(text: 'Produce');
    final qtyController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'pcs');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: unitController,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
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
                _addItem(
                  nameController.text,
                  categoryController.text,
                  double.tryParse(qtyController.text) ?? 1.0,
                  unitController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_template == null)
      return const Scaffold(body: Center(child: Text('Not found')));

    return Scaffold(
      appBar: AppBar(
        title: Text(_template!['name']),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/templates'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item['name']),
            subtitle: Text(
              '${item['category']} • ${item['default_qty']} ${item['unit']}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () => _deleteItem(item['id']),
            ),
          );
        },
      ),
    );
  }
}
