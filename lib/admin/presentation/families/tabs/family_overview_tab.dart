import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class FamilyOverviewTab extends StatefulWidget {
  final String familyId;
  final Map<String, dynamic> familyData;

  const FamilyOverviewTab({
    super.key,
    required this.familyId,
    required this.familyData,
  });

  @override
  State<FamilyOverviewTab> createState() => _FamilyOverviewTabState();
}

class _FamilyOverviewTabState extends State<FamilyOverviewTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  late Map<String, dynamic> _currentFamilyData;

  @override
  void initState() {
    super.initState();
    _currentFamilyData = widget.familyData;
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final membersResponse = await Supabase.instance.client
          .from('family_members')
          .select('role, user:users(id, display_name, email, avatar_url)')
          .eq('family_id', widget.familyId);

      if (mounted) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(membersResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching members: $e');
    }
  }

  Future<void> _deleteFamily() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family'),
        content: const Text(
          'Are you sure? This will mark the family as deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('families')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', widget.familyId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Family marked as deleted')),
          );
          // Update local state
          setState(() {
            _currentFamilyData = {
              ..._currentFamilyData,
              'deleted_at': DateTime.now().toIso8601String(),
            };
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _rotateInviteCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rotate Invite Code'),
        content: const Text('This will invalidate the old code. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rotate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Generate random 6 char code
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        final rnd = Random();
        final newCode = String.fromCharCodes(
          Iterable.generate(
            6,
            (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
          ),
        );

        await Supabase.instance.client
            .from('families')
            .update({'invite_code': newCode})
            .eq('id', widget.familyId);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('New Code: $newCode')));
          setState(() {
            _currentFamilyData = {
              ..._currentFamilyData,
              'invite_code': newCode,
            };
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _addMemberDialog() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email of the user to add.'),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              Navigator.pop(context); // Close dialog
              await _performAddMember(email);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAddMember(String email) async {
    try {
      // 1. Find User ID
      final userRes = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (userRes == null) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }

      final userId = userRes['id'];

      // 2. Insert into family_members
      await Supabase.instance.client.from('family_members').insert({
        'family_id': widget.familyId,
        'user_id': userId,
        'role': 'member', // Default role
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully')),
        );
        _fetchMembers();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding member: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDeleted = _currentFamilyData['deleted_at'] != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDeleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.red.withOpacity(0.1),
              child: const Text(
                'This family is deleted.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Actions Row
          Row(
            children: [
              if (!isDeleted)
                OutlinedButton.icon(
                  onPressed: _deleteFamily,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Soft Delete Family',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _rotateInviteCode,
                icon: const Icon(Icons.refresh),
                label: const Text('Rotate Invite Code'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text(
            'Metadata',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _buildInfoRow('ID', _currentFamilyData['id']),
          _buildInfoRow('Code', _currentFamilyData['invite_code']),
          _buildInfoRow('Created At', _currentFamilyData['created_at']),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members (${_members.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'Add Member Manually',
                onPressed: _addMemberDialog,
              ),
            ],
          ),
          const Divider(),
          if (_members.isEmpty) const Text('No members found.'),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              final user = member['user'] as Map<String, dynamic>;
              final role = member['role'] as String;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['avatar_url'] != null
                      ? NetworkImage(user['avatar_url'])
                      : null,
                  child: user['avatar_url'] == null
                      ? Text((user['display_name'] ?? '?')[0])
                      : null,
                ),
                title: Text(user['display_name'] ?? 'Unknown'),
                subtitle: Text(user['email'] ?? ''),
                trailing: Chip(label: Text(role)),
                onTap: () => context.go('/users/${user['id']}'),
              );
            },
          ),
        ],
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
