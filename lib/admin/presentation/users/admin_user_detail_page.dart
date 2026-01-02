import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserDetailPage extends ConsumerStatefulWidget {
  final String userId;

  const AdminUserDetailPage({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailPage> createState() =>
      _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends ConsumerState<AdminUserDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _families = [];
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

      // Fetch User Profile
      final userResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', widget.userId)
          .single();

      // Fetch Families (via family_members)
      final familiesResponse = await Supabase.instance.client
          .from('family_members')
          .select('role, families!inner(*)') // Join with families
          .eq('user_id', widget.userId);

      if (mounted) {
        setState(() {
          _user = userResponse;
          _families = List<Map<String, dynamic>>.from(familiesResponse);
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
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null)
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $_error')),
      );
    if (_user == null)
      return const Scaffold(body: Center(child: Text('User not found')));

    final user = _user!;
    final avatar = user['avatar_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(user['display_name'] ?? 'User Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/users'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: avatar != null
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar == null
                        ? Text(
                            (user['display_name'] ?? 'U')[0],
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user['display_name'] ?? 'No Name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    user['email'] ?? 'No Email',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(user['role'] ?? 'user')),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Raw Info
            const Text(
              'Metadata',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('ID', user['id']),
            _buildInfoRow('Created At', user['created_at']),
            _buildInfoRow('Updated At', user['updated_at']),

            const SizedBox(height: 32),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lock_reset),
                label: const Text('Send Password Reset Email'),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Send Password Reset?'),
                      content: Text(
                        'This will send a password reset email to ${user['email']}.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    try {
                      await Supabase.instance.client.auth.resetPasswordForEmail(
                        user['email'],
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reset email sent.')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Families',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_families.isEmpty)
              const Text('Not a member of any family.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _families.length,
                itemBuilder: (context, index) {
                  final membership = _families[index];
                  final family = membership['families'] as Map<String, dynamic>;
                  final role = membership['role'] as String;

                  return ListTile(
                    leading: const Icon(Icons.home),
                    title: Text(family['name'] ?? 'Unnamed Family'),
                    subtitle: Text('Role: $role'),
                    onTap: () {
                      // Navigate to Family Detail (Implement later)
                      // context.go('/families/${family['id']}');
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: SelectableText(value ?? '-')),
        ],
      ),
    );
  }
}
