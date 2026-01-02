import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_scaffold.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String? _error;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchUsers(query: query);
    });
  }

  Future<void> _fetchUsers({String? query}) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Start building the query
      PostgrestFilterBuilder<List<Map<String, dynamic>>> builder = Supabase
          .instance
          .client
          .from('users')
          .select();

      // Apply search filter if query exists
      if (query != null && query.isNotEmpty) {
        // Use 'or' filter for email OR display_name
        builder = builder.or(
          'email.ilike.%$query%,display_name.ilike.%$query%',
        );
      }

      // Apply ordering and limits
      // Note: We chain onto the possibly filtered builder
      final response = await builder
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
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
    return AdminScaffold(
      title: 'User Management',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _fetchUsers();
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final avatar = user['avatar_url'] as String?;
        final name = user['display_name'] as String? ?? 'User';
        final email = user['email'] as String? ?? 'No Email';
        final role = user['role'] as String? ?? 'user';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null ? Text(name[0].toUpperCase()) : null,
          ),
          title: Text('$name ${role == 'admin' ? '(Admin)' : ''}'),
          subtitle: Text(email),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.go('/users/${user['id']}');
          },
        );
      },
    );
  }
}
