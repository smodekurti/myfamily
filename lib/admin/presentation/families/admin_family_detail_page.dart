import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tabs
import 'tabs/family_overview_tab.dart';
import 'tabs/family_tasks_tab.dart';
import 'tabs/family_events_tab.dart';

class AdminFamilyDetailPage extends ConsumerStatefulWidget {
  final String familyId;

  const AdminFamilyDetailPage({super.key, required this.familyId});

  @override
  ConsumerState<AdminFamilyDetailPage> createState() =>
      _AdminFamilyDetailPageState();
}

class _AdminFamilyDetailPageState extends ConsumerState<AdminFamilyDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _family;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFamilyHeader();
  }

  Future<void> _fetchFamilyHeader() async {
    try {
      final familyResponse = await Supabase.instance.client
          .from('families')
          .select()
          .eq('id', widget.familyId)
          .single();

      if (mounted) {
        setState(() {
          _family = familyResponse;
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
    if (_family == null)
      return const Scaffold(body: Center(child: Text('Family not found')));

    final family = _family!;
    final isDeleted = family['deleted_at'] != null;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(family['name'] ?? 'Family Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/families'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Tasks'),
              Tab(text: 'Events'),
            ],
          ),
          actions: [
            if (isDeleted)
              const Chip(
                label: Text('Deleted', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        body: TabBarView(
          children: [
            FamilyOverviewTab(familyId: widget.familyId, familyData: family),
            FamilyTasksTab(familyId: widget.familyId),
            FamilyEventsTab(familyId: widget.familyId),
          ],
        ),
      ),
    );
  }
}
