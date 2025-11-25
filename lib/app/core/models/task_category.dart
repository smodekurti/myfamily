import 'package:flutter/material.dart';

/// Task category model with metadata
class TaskCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int defaultPoints;
  final String description;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.defaultPoints,
    required this.description,
  });

  /// Get display name with proper capitalization
  String get displayName => name[0].toUpperCase() + name.substring(1);
}

/// Task category definitions
class TaskCategories {
  // Core categories
  static const TaskCategory chore = TaskCategory(
    id: 'chore',
    name: 'Chore',
    icon: Icons.home,
    color: Color(0xFF14B8A6), // Teal
    defaultPoints: 10,
    description: 'General household tasks',
  );

  static const TaskCategory grocery = TaskCategory(
    id: 'grocery',
    name: 'Grocery',
    icon: Icons.shopping_cart,
    color: Color(0xFF06B6D4), // Cyan
    defaultPoints: 15,
    description: 'Shopping tasks with grocery lists',
  );

  // Household maintenance
  static const TaskCategory cleaning = TaskCategory(
    id: 'cleaning',
    name: 'Cleaning',
    icon: Icons.cleaning_services,
    color: Color(0xFF10B981), // Green
    defaultPoints: 12,
    description: 'Cleaning and tidying tasks',
  );

  static const TaskCategory laundry = TaskCategory(
    id: 'laundry',
    name: 'Laundry',
    icon: Icons.local_laundry_service,
    color: Color(0xFF8B5CF6), // Purple
    defaultPoints: 15,
    description: 'Washing, drying, and folding clothes',
  );

  static const TaskCategory maintenance = TaskCategory(
    id: 'maintenance',
    name: 'Maintenance',
    icon: Icons.build,
    color: Color(0xFFF59E0B), // Amber
    defaultPoints: 20,
    description: 'Home maintenance and repairs',
  );

  static const TaskCategory yardGarden = TaskCategory(
    id: 'yard_garden',
    name: 'Yard & Garden',
    icon: Icons.eco,
    color: Color(0xFF22C55E), // Green
    defaultPoints: 25,
    description: 'Outdoor yard and garden work',
  );

  // Personal & habits
  static const TaskCategory personalCare = TaskCategory(
    id: 'personal_care',
    name: 'Personal Care',
    icon: Icons.person,
    color: Color(0xFFEC4899), // Pink
    defaultPoints: 8,
    description: 'Personal hygiene and self-care',
  );

  static const TaskCategory homework = TaskCategory(
    id: 'homework',
    name: 'Homework',
    icon: Icons.school,
    color: Color(0xFF3B82F6), // Blue
    defaultPoints: 20,
    description: 'School work and studying',
  );

  static const TaskCategory exercise = TaskCategory(
    id: 'exercise',
    name: 'Exercise',
    icon: Icons.fitness_center,
    color: Color(0xFFEF4444), // Red
    defaultPoints: 25,
    description: 'Physical activity and fitness',
  );

  // Pet care
  static const TaskCategory petCare = TaskCategory(
    id: 'pet_care',
    name: 'Pet Care',
    icon: Icons.pets,
    color: Color(0xFFF97316), // Orange
    defaultPoints: 15,
    description: 'Taking care of family pets',
  );

  // Vehicle & transportation
  static const TaskCategory vehicle = TaskCategory(
    id: 'vehicle',
    name: 'Vehicle',
    icon: Icons.directions_car,
    color: Color(0xFF6366F1), // Indigo
    defaultPoints: 20,
    description: 'Vehicle maintenance and care',
  );

  // Financial & administrative
  static const TaskCategory bills = TaskCategory(
    id: 'bills',
    name: 'Bills & Finance',
    icon: Icons.payments,
    color: Color(0xFF10B981), // Green
    defaultPoints: 25,
    description: 'Financial tasks and bill payments',
  );

  static const TaskCategory appointments = TaskCategory(
    id: 'appointments',
    name: 'Appointments',
    icon: Icons.calendar_today,
    color: Color(0xFF8B5CF6), // Purple
    defaultPoints: 30,
    description: 'Medical and other appointments',
  );

  // Social & family
  static const TaskCategory familyTime = TaskCategory(
    id: 'family_time',
    name: 'Family Time',
    icon: Icons.family_restroom,
    color: Color(0xFFEC4899), // Pink
    defaultPoints: 40,
    description: 'Quality time with family',
  );

  static const TaskCategory errands = TaskCategory(
    id: 'errands',
    name: 'Errands',
    icon: Icons.shopping_bag,
    color: Color(0xFF06B6D4), // Cyan
    defaultPoints: 15,
    description: 'Running errands and quick tasks',
  );

  // Special occasions
  static const TaskCategory eventPlanning = TaskCategory(
    id: 'event_planning',
    name: 'Event Planning',
    icon: Icons.event,
    color: Color(0xFFF59E0B), // Amber
    defaultPoints: 35,
    description: 'Planning parties and events',
  );

  static const TaskCategory mealPrep = TaskCategory(
    id: 'meal_prep',
    name: 'Meal Prep',
    icon: Icons.restaurant,
    color: Color(0xFFEF4444), // Red
    defaultPoints: 20,
    description: 'Meal planning and preparation',
  );

  /// Get all available categories
  static List<TaskCategory> get all => [
        chore,
        grocery,
        cleaning,
        laundry,
        maintenance,
        yardGarden,
        personalCare,
        homework,
        exercise,
        petCare,
        vehicle,
        bills,
        appointments,
        familyTime,
        errands,
        eventPlanning,
        mealPrep,
      ];

  /// Get category by ID
  static TaskCategory? getById(String id) {
    try {
      return all.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get default category (chore)
  static TaskCategory get defaultCategory => chore;
}

/// Extension for category display
extension TaskCategoryExtension on String {
  /// Get TaskCategory from string ID
  TaskCategory? get toTaskCategory => TaskCategories.getById(this);

  /// Get display name for category
  String get categoryDisplayName {
    final category = toTaskCategory;
    return category?.displayName ?? this[0].toUpperCase() + substring(1);
  }

  /// Get icon for category
  IconData? get categoryIcon => toTaskCategory?.icon;

  /// Get color for category
  Color? get categoryColor => toTaskCategory?.color;

  /// Get default points for category
  int get categoryDefaultPoints => toTaskCategory?.defaultPoints ?? 10;
}

