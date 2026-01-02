import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/core/theme/app_theme.dart';
import '../widgets/admin_scaffold.dart';

class AdminFamiliesPage extends ConsumerStatefulWidget {
  const AdminFamiliesPage({super.key});

  @override
  ConsumerState<AdminFamiliesPage> createState() => _AdminFamiliesPageState();
}

class _AdminFamiliesPageState extends ConsumerState<AdminFamiliesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _families = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFamilies();
  }

  Future<void> _fetchFamilies() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Admins can view all families via RLS
      final response = await Supabase.instance.client
          .from('families')
          .select('*, family_members(count)')
          .order('created_at', ascending: false)
          .limit(50); // Pagination later

      if (mounted) {
        setState(() {
          _families = List<Map<String, dynamic>>.from(response);
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

  @override
  Widget build(BuildContext context) {
    // AdminScaffold to reuse the Drawer/AppBar
    return AdminScaffold(title: 'Families Management', body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFamilies,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_families.isEmpty) {
      return const Center(child: Text('No families found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _families.length,
      itemBuilder: (context, index) {
        final family = _families[index];
        final memberCount = family['family_members'] is List
            ? (family['family_members'] as List).isNotEmpty
                  ? (family['family_members'] as List)[0]['count']
                  : 0
            : 0;
        // Note: count query structure might differ based on how Supabase returns it.
        // Usually .select('*, family_members(count)') returns [{count: N}]

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                (family['name'] as String? ?? '?')[0].toUpperCase(),
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            title: Text(family['name'] as String? ?? 'Unnamed Family'),
            subtitle: Text(
              'ID: ${family['id']} • Created: ${family['created_at']}',
            ),
            trailing: Chip(
              label: Text('$memberCount Members'), // This might need debugging
            ),
            onTap: () {
              // TODO: Navigate to Family Details
            },
          ),
        );
      },
    );
  }
}
