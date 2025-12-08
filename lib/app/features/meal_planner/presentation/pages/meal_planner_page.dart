import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../common/responsive/responsive_helper.dart';

class MealPlannerPage extends ConsumerStatefulWidget {
  const MealPlannerPage({super.key});

  @override
  ConsumerState<MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends ConsumerState<MealPlannerPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamilyId = ref.watch(currentFamilyIdProvider);
    final planAsync = ref.watch(
      currentWeekMealPlanProvider(currentFamilyId ?? ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Recipes',
            onPressed: () => context.push(AppConstants.routeRecipes),
          ),
        ],
      ),
      body: planAsync.when(
        data: (plan) {
          // Normalize dates
          final today = DateTime.now();
          final startDate = plan.startDate;
          final days = List.generate(
            7,
            (index) => startDate.add(Duration(days: index)),
          );

          // Get entries for selected date
          final selectedDayEntries =
              plan.entries
                  ?.where((e) => DateUtils.isSameDay(e.mealDate, _selectedDate))
                  .toList() ??
              [];

          return Column(
            children: [
              // Month/Year Header
              Padding(
                padding: ResponsiveHelper.padding(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      _getMonthRangeText(days.first, days.last),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Future: Add Week Navigation Arrows here
                  ],
                ),
              ),

              // Horizontal Date Strip
              _buildDateStrip(days, today),

              const Divider(height: 1),

              // Main Content
              Expanded(
                child: ListView(
                  padding: ResponsiveHelper.padding(all: 16),
                  children: [
                    _buildSectionHeader('Planned Meals'),
                    SizedBox(height: 16.h),
                    _buildMealCard(
                      context,
                      'Breakfast',
                      Icons.wb_sunny_outlined,
                      Colors.orange,
                      selectedDayEntries,
                      plan.id,
                      plan.familyId,
                      _selectedDate,
                    ),
                    SizedBox(height: 16.h),
                    _buildMealCard(
                      context,
                      'Lunch',
                      Icons.restaurant,
                      Colors.green,
                      selectedDayEntries,
                      plan.id,
                      plan.familyId,
                      _selectedDate,
                    ),
                    SizedBox(height: 16.h),
                    _buildMealCard(
                      context,
                      'Dinner',
                      Icons.dinner_dining,
                      Colors.indigo,
                      selectedDayEntries,
                      plan.id,
                      plan.familyId,
                      _selectedDate,
                    ),
                    SizedBox(height: 16.h),
                    _buildMealCard(
                      context,
                      'Snack',
                      Icons.local_cafe_outlined,
                      Colors.teal,
                      selectedDayEntries,
                      plan.id,
                      plan.familyId,
                      _selectedDate,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: $err'),
          ),
        ),
      ),
    );
  }

  String _getMonthRangeText(DateTime start, DateTime end) {
    if (start.month == end.month) {
      return DateFormat('MMMM yyyy').format(start);
    } else {
      // Spans two months
      final startFormat = DateFormat('MMM');
      final endFormat = DateFormat('MMM yyyy');
      if (start.year != end.year) {
        // Spans two years (rare but possible, e.g. Dec 29 - Jan 4)
        return '${DateFormat('MMM yyyy').format(start)} - ${DateFormat('MMM yyyy').format(end)}';
      }
      return '${startFormat.format(start)} - ${endFormat.format(end)}';
    }
  }

  Widget _buildDateStrip(List<DateTime> days, DateTime today) {
    return Container(
      height: 100.h,
      color: Theme.of(context).cardColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: ResponsiveHelper.padding(horizontal: 16, vertical: 16),
        itemCount: days.length,
        separatorBuilder: (context, index) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = DateUtils.isSameDay(day, _selectedDate);
          final isToday = DateUtils.isSameDay(day, today);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : isToday
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(30.r), // Pill shape
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : isToday
                      ? AppTheme.primaryColor
                      : Colors.grey.withOpacity(0.2),
                  width: isToday && !isSelected ? 1.5 : 0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => context.push(AppConstants.routeRecipes),
          icon: const Icon(Icons.menu_book),
          label: const Text('My Recipes'),
        ),
      ],
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    String mealType,
    IconData icon,
    Color color,
    List<dynamic> entries,
    String planId,
    String familyId,
    DateTime date,
  ) {
    // Correctly cast and filter entries
    final entry = entries
        .map((e) => e as dynamic)
        .where((e) => e.mealType.toLowerCase() == mealType.toLowerCase())
        .firstOrNull;

    final isPlanned = entry != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.go(
              '${AppConstants.routeMealPlanner}/${AppConstants.routeMealSlotEdit}/$date/$mealType/$familyId/$planId',
              extra: entry,
            );
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: ResponsiveHelper.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon/Image
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(icon, color: color, size: 24.sp),
                    ),
                    SizedBox(width: 16.w),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealType,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isPlanned
                                ? (entry.recipeTitle as String? ??
                                      entry.customNote as String? ??
                                      'Custom Meal')
                                : 'Not planned',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: isPlanned
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isPlanned
                                      ? null
                                      : Colors.grey.withOpacity(0.5),
                                  fontStyle: isPlanned
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                          ),
                          if (isPlanned && entry.recipeTitle != null) ...[
                            SizedBox(height: 4.h),
                            // Could add tags or time here if fetched
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 12.sp,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '30 min', // Placeholder or fetch from recipe
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action Icon
                    Icon(
                      isPlanned
                          ? Icons.chevron_right
                          : Icons.add_circle_outline,
                      color: isPlanned ? Colors.grey : AppTheme.primaryColor,
                      size: 24.sp,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
