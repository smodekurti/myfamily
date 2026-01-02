import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyEventsTab extends StatefulWidget {
  final String familyId;

  const FamilyEventsTab({super.key, required this.familyId});

  @override
  State<FamilyEventsTab> createState() => _FamilyEventsTabState();
}

class _FamilyEventsTabState extends State<FamilyEventsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      setState(() => _isLoading = true);
      final response = await Supabase.instance.client
          .from('events')
          .select()
          .eq('family_id', widget.familyId)
          .order('start_time', ascending: false);

      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      await Supabase.instance.client.from('events').delete().eq('id', id);
      _fetchEvents();
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
    if (_events.isEmpty) return const Center(child: Text('No events found.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final start = DateTime.tryParse(event['start_time'] ?? '');

        return Card(
          child: ListTile(
            leading: const Icon(Icons.event),
            title: Text(event['title'] ?? 'Untitled'),
            subtitle: Text(
              start != null
                  ? '${start.month}/${start.day} ${start.hour}:${start.minute}'
                  : 'No Date',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () => _deleteEvent(event['id']),
            ),
          ),
        );
      },
    );
  }
}
