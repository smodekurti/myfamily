import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_scaffold.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  bool _isLoading = true;
  int _familyCount = 0;
  int _userCount = 0;
  List<Map<String, dynamic>> _recentFamilies = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final client = Supabase.instance.client;

      // Parallel fetching with dynamic type to satisfy Future.wait generic
      final results = await Future.wait<dynamic>([
        client.from('families').count(),
        client.from('users').count(),
        client
            .from('families')
            .select()
            .order('created_at', ascending: false)
            .limit(5),
      ]);

      if (mounted) {
        setState(() {
          _familyCount = results[0] as int;
          _userCount = results[1] as int;
          _recentFamilies = List<Map<String, dynamic>>.from(results[2] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Silently fail or show minimal error
        setState(() => _isLoading = false);
        debugPrint('Error fetching stats: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AdminScaffold(
        title: 'Dashboard',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AdminScaffold(
      title: 'Dashboard',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  context,
                  title: 'Total Families',
                  value: '$_familyCount',
                  icon: Icons.people_alt,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  title: 'Total Users',
                  value: '$_userCount',
                  icon: Icons.person,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Recent Families',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentFamilies.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final family = _recentFamilies[index];
                  return ListTile(
                    leading: const Icon(Icons.group_add),
                    title: Text(family['name'] ?? 'Unnamed'),
                    subtitle: Text('ID: ${family['id']}'),
                    trailing: Text(
                      _formatDate(family['created_at']),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    final date = DateTime.tryParse(isoString);
    if (date == null) return isoString;
    return '${date.month}/${date.day}/${date.year}';
  }
}
