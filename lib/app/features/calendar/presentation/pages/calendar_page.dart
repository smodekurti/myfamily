import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/permission_aware_widget.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/event_model.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  final TextEditingController _searchController = TextEditingController();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _viewMode = 'Month'; // 'Month', 'Week', 'Day', 'List'
  String? _selectedMemberId; // null means "All Members"
  bool _isSearchMode = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Color palette for events
  final List<Color> _eventColors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];

  Color _getEventColor(EventModel event) {
    if (event.color != null) {
      // Try to parse color from string
      try {
        return Color(int.parse(event.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback to default
      }
    }
    // Use hash of event ID to get consistent color
    final hash = event.id.hashCode;
    return _eventColors[hash.abs() % _eventColors.length];
  }
  
  List<EventModel> _searchEvents(List<EventModel> events, String query) {
    if (query.isEmpty) return events;
    
    final lowerQuery = query.toLowerCase();
    return events.where((event) {
      // Search in title
      if (event.title.toLowerCase().contains(lowerQuery)) return true;
      
      // Search in description
      if (event.description != null && 
          event.description!.toLowerCase().contains(lowerQuery)) return true;
      
      // Search in location
      if (event.location != null && 
          event.location!.toLowerCase().contains(lowerQuery)) return true;
      
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final eventsAsync = currentFamily != null
        ? ref.watch(familyEventsProvider(currentFamily.id))
        : const AsyncValue<List<EventModel>>.data(<EventModel>[]);

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // View Selector (Month/Week/Day/List)
              _buildViewSelector(context),
              
              // Search bar (shown when search mode is active)
              if (_isSearchMode)
                Container(
                  padding: ResponsiveHelper.padding(all: 16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search events...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.w(8)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSearchMode = false;
                            _searchController.clear();
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              
              // Member Filter (hide when searching)
              if (!_isSearchMode)
                _buildMemberFilter(context),
              
              // Calendar Widget or List View
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Refresh from server when user pulls to refresh
                    final currentFamily = ref.read(currentFamilyProvider);
                    if (currentFamily != null) {
                      ref.invalidate(familyEventsProvider(currentFamily.id));
                    }
                    // Wait a moment for the stream to fetch new data
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: _viewMode == 'List' || _isSearchMode
                      ? _buildEventsList(context, eventsAsync)
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              // Calendar
                              _buildCalendar(context, eventsAsync),
                              
                              // Today's Events Section
                              _buildTodaysEvents(context, eventsAsync),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: PermissionAwareWidget(
          action: 'create_event',
          child: FloatingActionButton(
          onPressed: () => _showCreateEventDialog(context, _selectedDay),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildViewSelector(BuildContext context) {
    return Container(
      margin: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: ResponsiveHelper.borderRadius(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildViewButton(context, 'Month', _viewMode == 'Month'),
          ),
          Expanded(
            child: _buildViewButton(context, 'Week', _viewMode == 'Week'),
          ),
          Expanded(
            child: _buildViewButton(context, 'Day', _viewMode == 'Day'),
          ),
          Expanded(
            child: _buildViewButton(context, 'List', _viewMode == 'List'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(BuildContext context, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _viewMode = label;
          if (label == 'Week') {
            _calendarFormat = CalendarFormat.week;
          } else if (label == 'Day') {
            _calendarFormat = CalendarFormat.twoWeeks;
          } else if (label == 'List') {
            // List view doesn't need calendar format
          } else {
            _calendarFormat = CalendarFormat.month;
          }
        });
      },
      borderRadius: ResponsiveHelper.borderRadius(12),
      child: Container(
        padding: ResponsiveHelper.padding(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: ResponsiveHelper.borderRadius(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: ResponsiveHelper.sp(12),
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberFilter(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    if (currentFamily == null) return const SizedBox.shrink();
    
    final familyMembersAsync = ref.watch(familyMembersProvider(currentFamily.id));
    
    return familyMembersAsync.when(
      data: (members) {
        if (members.isEmpty) return const SizedBox.shrink();
        
        return Container(
          margin: ResponsiveHelper.padding(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.filter_list,
                size: ResponsiveHelper.iconSize(18),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              SizedBox(width: ResponsiveHelper.w(8)),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedMemberId,
                  decoration: InputDecoration(
                    labelText: 'Filter by member',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.sp(14),
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: ResponsiveHelper.iconSize(16),
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(width: ResponsiveHelper.w(8)),
                          Text(
                            'All Members',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.sp(14),
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...members.map((member) {
                      return DropdownMenuItem<String?>(
                        value: member.uid,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvatarWidget(
                              avatarPath: member.photoURL,
                              radius: ResponsiveHelper.r(12),
                              displayName: member.displayName,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              textColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            SizedBox(width: ResponsiveHelper.w(8)),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: ResponsiveHelper.w(150),
                              ),
                              child: Text(
                                member.displayName.isNotEmpty
                                    ? member.displayName
                                    : 'Unknown',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.sp(14),
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMemberId = value;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCalendar(BuildContext context, AsyncValue<List<EventModel>> eventsAsync) {
    return eventsAsync.when(
      data: (events) {
        // Filter events by selected member (show events created by the selected member)
        final filteredEvents = _selectedMemberId == null
            ? events
            : events.where((event) {
                // Show event if it was created by the selected member
                return event.createdBy == _selectedMemberId;
              }).toList();
        
        // Group events by date
        final eventsByDate = <DateTime, List<EventModel>>{};
        for (final event in filteredEvents) {
          final eventDate = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );
          eventsByDate.putIfAbsent(eventDate, () => []).add(event);
        }

        return Container(
          margin: ResponsiveHelper.padding(all: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: ResponsiveHelper.borderRadius(16),
          ),
          child: TableCalendar<EventModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              // Only highlight as selected if it's not today
              // Today will be highlighted separately with todayDecoration
              return isSameDay(_selectedDay, day) && !isSameDay(day, DateTime.now());
            },
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            eventLoader: (day) {
              final date = DateTime(day.year, day.month, day.day);
              return eventsByDate[date] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              outsideTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              weekendTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              defaultTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              // Selected day styling - using orange for high contrast
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              // Today styling - using teal/primary for high contrast
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              markerDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 6,
              markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ) ?? TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.sp(11),
              ),
              weekendStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.sp(11),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                // Custom weekday builder to use single-letter abbreviations
                // Since calendar starts on Sunday, map: Sun=0, Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6
                // DateTime.weekday: Mon=1, Tue=2, ..., Sun=7
                // We need: Sun=0, Mon=1, ..., Sat=6
                final weekdayAbbreviations = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                // Convert DateTime.weekday (1-7) to our index (0-6) where Sunday=0
                final weekdayIndex = day.weekday == 7 ? 0 : day.weekday;
                return Center(
                  child: Text(
                    weekdayAbbreviations[weekdayIndex],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.sp(11),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                );
              },
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(3).map((event) {
                    final color = _getEventColor(event);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error loading events: $error'),
      ),
    );
  }

  Widget _buildTodaysEvents(BuildContext context, AsyncValue<List<EventModel>> eventsAsync) {
    return eventsAsync.when(
      data: (events) {
        // Filter events by selected member (show events created by the selected member)
        final filteredEvents = _selectedMemberId == null
            ? events
            : events.where((event) {
                // Show event if it was created by the selected member
                return event.createdBy == _selectedMemberId;
              }).toList();
        
        // Get events for the selected day (or today if no day is selected)
        final selectedDate = _selectedDay;
        final selectedDateEvents = filteredEvents.where((event) {
          final eventDate = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );
          final targetDate = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
          );
          return eventDate == targetDate;
        }).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        if (selectedDateEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        // Determine if the selected date is today
        final today = DateTime.now();
        final isToday = selectedDate.year == today.year &&
            selectedDate.month == today.month &&
            selectedDate.day == today.day;

        return Padding(
          padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday
                    ? 'Today, ${DateFormat('MMMM d').format(selectedDate)}'
                    : DateFormat('EEEE, MMMM d').format(selectedDate),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: ResponsiveHelper.h(12)),
              ...selectedDateEvents.map((event) => _buildEventCard(context, event)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEventsList(BuildContext context, AsyncValue<List<EventModel>> eventsAsync) {
    return eventsAsync.when(
      data: (events) {
        var filteredEvents = events;
        
        // Apply search filter if in search mode
        if (_isSearchMode && _searchController.text.isNotEmpty) {
          filteredEvents = _searchEvents(filteredEvents, _searchController.text);
        }
        
        // Filter events by selected member (show events created by the selected member) - only when not searching
        if (!_isSearchMode && _selectedMemberId != null) {
          filteredEvents = filteredEvents.where((event) {
            // Show event if it was created by the selected member
            return event.createdBy == _selectedMemberId;
          }).toList();
        }
        
        // Sort events by start time
        filteredEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        
        if (filteredEvents.isEmpty) {
          return Center(
            child: Padding(
              padding: ResponsiveHelper.padding(all: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearchMode ? Icons.search_off : Icons.event_busy,
                    size: ResponsiveHelper.iconSize(64),
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  SizedBox(height: ResponsiveHelper.h(16)),
                  Text(
                    _isSearchMode ? 'No events found' : 'No events',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Group events by date
        final Map<String, List<EventModel>> eventsByDate = {};
        for (final event in filteredEvents) {
          final dateKey = DateFormat('yyyy-MM-dd').format(event.startTime);
          eventsByDate.putIfAbsent(dateKey, () => []).add(event);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show search results title if searching
            if (_isSearchMode)
              Padding(
                padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
                child: Text(
                  'Search Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
                itemCount: eventsByDate.length,
                itemBuilder: (context, index) {
                  final dateKey = eventsByDate.keys.elementAt(index);
                  final dateEvents = eventsByDate[dateKey]!;
                  final date = DateTime.parse(dateKey);
                  
                  // Determine if this date is today
                  final today = DateTime.now();
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Padding(
                        padding: ResponsiveHelper.padding(vertical: 12, horizontal: 4),
                        child: Text(
                          isToday
                              ? 'Today, ${DateFormat('MMMM d, yyyy').format(date)}'
                              : DateFormat('EEEE, MMMM d, yyyy').format(date),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Events for this date
                      ...dateEvents.map((event) => _buildEventCard(context, event)),
                      SizedBox(height: ResponsiveHelper.h(8)),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: ResponsiveHelper.padding(all: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveHelper.iconSize(64),
                color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(height: ResponsiveHelper.h(16)),
                  Text(
                'Error loading events',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              SizedBox(height: ResponsiveHelper.h(8)),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final eventColor = _getEventColor(event);
    final timeFormat = DateFormat('h:mm a');
    final startTime = timeFormat.format(event.startTime);
    final endTime = timeFormat.format(event.endTime);
    
    // Get participants display names
    final participants = ref.watch(familyMembersProvider(event.familyId));
    final participantNames = participants.when(
      data: (members) {
        if (event.participants.isEmpty) return 'All';
        final names = event.participants.map((id) {
          final member = members.firstWhere(
            (m) => m.uid == id,
            orElse: () => members.firstWhere(
              (m) => m.displayName.isNotEmpty,
              orElse: () => members.first,
            ),
          );
          return member.displayName;
        }).toList();
        return names.join(' & ');
      },
      loading: () => 'Loading...',
      error: (_, __) => 'All',
    );

    return Card(
      margin: ResponsiveHelper.padding(bottom: 8),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: ResponsiveHelper.padding(
          horizontal: 12,
          vertical: 8,
        ),
        leading: Container(
          width: ResponsiveHelper.w(8),
          height: ResponsiveHelper.h(8),
          decoration: BoxDecoration(
            color: eventColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          event.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.sp(14),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: ResponsiveHelper.h(2)),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: ResponsiveHelper.sp(12),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: ResponsiveHelper.w(4)),
              Text(
                '$startTime - $endTime',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: ResponsiveHelper.sp(12),
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(8)),
              Icon(
                Icons.people,
                size: ResponsiveHelper.sp(12),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: ResponsiveHelper.w(4)),
              Expanded(
                child: Text(
                  participantNames,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: ResponsiveHelper.sp(12),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(8)),
              // Creator avatar
              Consumer(
                builder: (context, ref, child) {
                  final creatorProfileAsync = ref.watch(userProfileProvider(event.createdBy));
                  return creatorProfileAsync.when(
                    data: (profile) {
                      final displayName = profile?.displayName ?? '?';
                      final avatarUrl = profile?.photoURL;
                      
                      return AvatarWidget(
                        avatarPath: avatarUrl,
                        radius: ResponsiveHelper.r(10),
                        displayName: displayName,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      );
                    },
                    loading: () => CircleAvatar(
                      radius: ResponsiveHelper.r(10),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      child: SizedBox(
                        width: ResponsiveHelper.w(10),
                        height: ResponsiveHelper.h(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    error: (_, __) => CircleAvatar(
                      radius: ResponsiveHelper.r(10),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        size: ResponsiveHelper.sp(12),
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        trailing: Consumer(
          builder: (context, ref, child) {
            return FutureBuilder<List<bool>>(
              future: Future.wait([
                checkPermission(ref, 'edit_event'),
                checkPermission(ref, 'delete_event'),
              ]),
              builder: (context, snapshot) {
                final canEdit = snapshot.data?[0] ?? false;
                final canDelete = snapshot.data?[1] ?? false;
                
                if (!canEdit && !canDelete) {
                  return const SizedBox.shrink();
                }
                
                return PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: ResponsiveHelper.iconSize(18),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
                  onSelected: (value) async {
            if (value == 'edit') {
                      if (canEdit) {
              _showEditEventDialog(context, event);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('You do not have permission to edit events'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
            } else if (value == 'delete') {
                      if (canDelete) {
              _deleteEvent(context, event);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('You do not have permission to delete events'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
            }
          },
          itemBuilder: (context) => [
                    if (canEdit)
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
                    if (canDelete)
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCreateEventDialog(BuildContext context, DateTime? selectedDate) async {
    final currentFamily = ref.read(currentFamilyProvider);
    final currentUser = ref.read(currentUserProvider);
    
    if (currentFamily == null || currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family or user not found')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _CreateEventDialog(
        familyId: currentFamily.id,
        createdBy: currentUser.id,
        initialDate: selectedDate,
        onSave: (title, description, startTime, endTime, location, color, participants) async {
          try {
            final calendarRepo = ref.read(calendarRepositoryProvider);
            await calendarRepo.createEvent(
              familyId: currentFamily.id,
              title: title,
              description: description.isEmpty ? null : description,
              startTime: startTime,
              endTime: endTime,
              location: location.isEmpty ? null : location,
              createdBy: currentUser.id,
              color: color,
              participants: participants,
            );
            return true;
          } catch (e) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('Error creating event: ${e.toString()}'),
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
              );
            }
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      // Invalidate the events provider to refresh the calendar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(familyEventsProvider(currentFamily.id));
      });
      
      // Small delay to ensure the stream picks up the change
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _showEditEventDialog(BuildContext context, EventModel event) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _EditEventDialog(
        event: event,
        onSave: (title, description, startTime, endTime, location, color, participants) async {
          try {
            final calendarRepo = ref.read(calendarRepositoryProvider);
            await calendarRepo.updateEvent(
              eventId: event.id,
              title: title,
              description: description.isEmpty ? null : description,
              startTime: startTime,
              endTime: endTime,
              location: location.isEmpty ? null : location,
              color: color,
              participants: participants,
            );
            return true;
          } catch (e) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('Error updating event: ${e.toString()}'),
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
              );
            }
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      // Invalidate the events provider to refresh the calendar
      final currentFamily = ref.read(currentFamilyProvider);
      if (currentFamily != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(familyEventsProvider(currentFamily.id));
        });
        
        // Small delay to ensure the stream picks up the change
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _deleteEvent(BuildContext context, EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final calendarRepo = ref.read(calendarRepositoryProvider);
        await calendarRepo.deleteEvent(event.id);
        
        // Invalidate the events provider to refresh the calendar
        final currentFamily = ref.read(currentFamilyProvider);
        if (currentFamily != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(familyEventsProvider(currentFamily.id));
          });
          
          // Small delay to ensure the stream picks up the change
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e')),
          );
        }
      }
    }
  }
}

// Standalone dialog widget for creating events
class _CreateEventDialog extends StatefulWidget {
  final String familyId;
  final String createdBy;
  final DateTime? initialDate;
  final Future<bool> Function(
    String title,
    String description,
    DateTime startTime,
    DateTime endTime,
    String location,
    String? color,
    List<String> participants,
  ) onSave;

  const _CreateEventDialog({
    required this.familyId,
    required this.createdBy,
    this.initialDate,
    required this.onSave,
  });

  @override
  State<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<_CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  String? _selectedColor;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Green', 'color': Colors.green, 'value': '#4CAF50'},
    {'name': 'Blue', 'color': Colors.blue, 'value': '#2196F3'},
    {'name': 'Orange', 'color': Colors.orange, 'value': '#FF9800'},
    {'name': 'Purple', 'color': Colors.purple, 'value': '#9C27B0'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    
    // Initialize dates based on selected date or today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = widget.initialDate != null
        ? DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day)
        : today;
    
    // If initial date is in the past, use today instead
    if (initialDate.isBefore(today)) {
      _startDate = today;
    } else {
      _startDate = initialDate;
    }
    
    _endDate = _startDate;
    
    // Set start time - if it's today, use current time, otherwise use 9 AM
    if (isSameDay(_startDate, today)) {
      _startTime = TimeOfDay.fromDateTime(now);
      // End time is 1 hour later
      final endHour = (now.hour + 1) % 24;
      _endTime = TimeOfDay(hour: endHour, minute: now.minute);
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: today, // Cannot select past dates
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // If start date is today, ensure start time is not in the past
          if (isSameDay(picked, today)) {
            final currentTime = TimeOfDay.fromDateTime(now);
            if (_startTime.hour < currentTime.hour || 
                (_startTime.hour == currentTime.hour && _startTime.minute < currentTime.minute)) {
              _startTime = TimeOfDay(
                hour: currentTime.hour,
                minute: currentTime.minute,
              );
            }
          }
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isStartToday = isSameDay(_startDate, today);
    
    TimeOfDay? picked;
    if (isStart && isStartToday) {
      // For start time on today, ensure we can't select past times
      final currentTime = TimeOfDay.fromDateTime(now);
      picked = await showTimePicker(
        context: context,
        initialTime: _startTime.hour < currentTime.hour || 
                     (_startTime.hour == currentTime.hour && _startTime.minute < currentTime.minute)
            ? currentTime
            : _startTime,
        initialEntryMode: TimePickerEntryMode.dial,
      );
      // Validate that selected time is not in the past
      if (picked != null) {
        if (picked.hour < currentTime.hour || 
            (picked.hour == currentTime.hour && picked.minute < currentTime.minute)) {
          setState(() {
            _errorMessage = 'Cannot select a time in the past';
          });
          return;
        } else {
          setState(() {
            _errorMessage = null;
          });
        }
      }
    } else {
      picked = await showTimePicker(
        context: context,
        initialTime: isStart ? _startTime : _endTime,
      );
    }
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked!;
        } else {
          _endTime = picked!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(16),
      ),
      title: const Text('Create Event'),
      content: SizedBox(
        width: ResponsiveHelper.w(400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter event title';
                    }
                    return null;
                  },
                  autofocus: false,
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_startDate),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                          ),
                          child: Text(_startTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_endDate),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                          ),
                          child: Text(_endTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location (optional)',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  decoration: InputDecoration(
                    labelText: 'Color (optional)',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Default')),
                    ..._colorOptions.map((option) {
                      return DropdownMenuItem(
                        value: option['value'] as String,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: option['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.w(8)),
                            Text(option['name'] as String),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedColor = value;
                      _errorMessage = null; // Clear error when user makes changes
                    });
                  },
                ),
                // Error message display
                if (_errorMessage != null) ...[
                  SizedBox(height: ResponsiveHelper.h(12)),
                  Container(
                    padding: ResponsiveHelper.padding(all: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: ResponsiveHelper.borderRadius(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: ResponsiveHelper.iconSize(20),
                        ),
                        SizedBox(width: ResponsiveHelper.w(8)),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: ResponsiveHelper.sp(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  final startDateTime = DateTime(
                    _startDate.year,
                    _startDate.month,
                    _startDate.day,
                    _startTime.hour,
                    _startTime.minute,
                  );
                  final endDateTime = DateTime(
                    _endDate.year,
                    _endDate.month,
                    _endDate.day,
                    _endTime.hour,
                    _endTime.minute,
                  );

                  // Validate that start time is not in the past
                  final now = DateTime.now();
                  if (startDateTime.isBefore(now)) {
                    setState(() {
                      _errorMessage = 'Cannot create events in the past';
                    });
                    return;
                  }

                  if (endDateTime.isBefore(startDateTime)) {
                    setState(() {
                      _errorMessage = 'End time must be after start time';
                    });
                    return;
                  }

                  // Clear any previous errors
                  setState(() {
                    _errorMessage = null;
                  });

                  setState(() => _isLoading = true);

                  try {
                    final success = await widget.onSave(
                      _titleController.text.trim(),
                      _descriptionController.text.trim(),
                      startDateTime,
                      endDateTime,
                      _locationController.text.trim(),
                      _selectedColor,
                      [], // Participants - can be added later
                    );
                    if (mounted) {
                      Navigator.of(context).pop(success);
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop(false);
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: _isLoading
              ? SizedBox(
                  width: ResponsiveHelper.w(20),
                  height: ResponsiveHelper.h(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

// Standalone dialog widget for editing events
class _EditEventDialog extends StatefulWidget {
  final EventModel event;
  final Future<bool> Function(
    String title,
    String description,
    DateTime startTime,
    DateTime endTime,
    String location,
    String? color,
    List<String> participants,
  ) onSave;

  const _EditEventDialog({
    required this.event,
    required this.onSave,
  });

  @override
  State<_EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<_EditEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  String? _selectedColor;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Green', 'color': Colors.green, 'value': '#4CAF50'},
    {'name': 'Blue', 'color': Colors.blue, 'value': '#2196F3'},
    {'name': 'Orange', 'color': Colors.orange, 'value': '#FF9800'},
    {'name': 'Purple', 'color': Colors.purple, 'value': '#9C27B0'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description ?? '');
    _locationController = TextEditingController(text: widget.event.location ?? '');
    _startDate = widget.event.startTime;
    _startTime = TimeOfDay.fromDateTime(widget.event.startTime);
    _endDate = widget.event.endTime;
    _endTime = TimeOfDay.fromDateTime(widget.event.endTime);
    _selectedColor = widget.event.color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(16),
      ),
      title: const Text('Edit Event'),
      content: SizedBox(
        width: ResponsiveHelper.w(400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter event title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_startDate),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                          ),
                          child: Text(_startTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_endDate),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                          ),
                          child: Text(_endTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location (optional)',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  decoration: InputDecoration(
                    labelText: 'Color (optional)',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Default')),
                    ..._colorOptions.map((option) {
                      return DropdownMenuItem(
                        value: option['value'] as String,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: option['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.w(8)),
                            Text(option['name'] as String),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedColor = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  final startDateTime = DateTime(
                    _startDate.year,
                    _startDate.month,
                    _startDate.day,
                    _startTime.hour,
                    _startTime.minute,
                  );
                  final endDateTime = DateTime(
                    _endDate.year,
                    _endDate.month,
                    _endDate.day,
                    _endTime.hour,
                    _endTime.minute,
                  );

                  if (endDateTime.isBefore(startDateTime)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('End time must be after start time'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    final success = await widget.onSave(
                      _titleController.text.trim(),
                      _descriptionController.text.trim(),
                      startDateTime,
                      endDateTime,
                      _locationController.text.trim(),
                      _selectedColor,
                      widget.event.participants,
                    );
                    if (mounted) {
                      Navigator.of(context).pop(success);
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop(false);
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: _isLoading
              ? SizedBox(
                  width: ResponsiveHelper.w(20),
                  height: ResponsiveHelper.h(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
