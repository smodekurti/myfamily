/// Application-wide constants
/// 
/// This file contains all configuration values, limits, and constants
/// to prevent hardcoding throughout the application.
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // ============================================================================
  // API & Network Configuration
  // ============================================================================
  
  /// Maximum file upload size in bytes (10MB)
  static const int maxFileUploadSize = 10 * 1024 * 1024;
  
  /// Maximum image upload size in bytes (5MB)
  static const int maxImageUploadSize = 5 * 1024 * 1024;
  
  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);
  
  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 10);

  // ============================================================================
  // Image Configuration
  // ============================================================================
  
  /// Supported image formats
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  
  /// Maximum image dimensions for upload (width or height)
  static const int maxImageDimension = 2048;
  
  /// Image compression quality (0.0 to 1.0)
  static const double imageCompressionQuality = 0.85;
  
  /// Profile picture dimensions
  static const int profilePictureSize = 800;

  // ============================================================================
  // UI Configuration
  // ============================================================================
  
  /// Default animation duration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  /// Long animation duration
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  /// Short animation duration
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  /// Snackbar display duration
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  /// Long snackbar display duration
  static const Duration longSnackBarDuration = Duration(seconds: 5);
  
  /// Debounce duration for search inputs
  static const Duration searchDebounceDuration = Duration(milliseconds: 500);
  
  /// Splash screen display duration
  static const Duration splashScreenDuration = Duration(seconds: 3);

  // ============================================================================
  // Validation Limits
  // ============================================================================
  
  /// Minimum password length
  static const int minPasswordLength = 6;
  
  /// Maximum password length
  static const int maxPasswordLength = 128;
  
  /// Minimum display name length
  static const int minDisplayNameLength = 2;
  
  /// Maximum display name length
  static const int maxDisplayNameLength = 50;
  
  /// Maximum email length
  static const int maxEmailLength = 254;
  
  /// Maximum family name length
  static const int maxFamilyNameLength = 50;
  
  /// Maximum task title length
  static const int maxTaskTitleLength = 100;
  
  /// Maximum task description length
  static const int maxTaskDescriptionLength = 1000;
  
  /// Maximum event title length
  static const int maxEventTitleLength = 100;
  
  /// Maximum event description length
  static const int maxEventDescriptionLength = 1000;

  // ============================================================================
  // Pagination & Limits
  // ============================================================================
  
  /// Default page size for paginated lists
  static const int defaultPageSize = 20;
  
  /// Large page size for paginated lists
  static const int largePageSize = 50;
  
  /// Maximum items per page
  static const int maxPageSize = 100;

  // ============================================================================
  // Calendar Configuration
  // ============================================================================
  
  /// Default reminder times in minutes before event
  static const List<int> defaultReminderMinutes = [
    0,      // At time of event
    15,     // 15 minutes before
    60,     // 1 hour before
    1440,   // 1 day before
  ];
  
  /// Maximum number of reminders per event
  static const int maxRemindersPerEvent = 5;
  
  /// Maximum number of attendees per event
  static const int maxAttendeesPerEvent = 50;

  // ============================================================================
  // Family Configuration
  // ============================================================================
  
  /// Maximum number of families a user can join
  static const int maxFamiliesPerUser = 10;
  
  /// Maximum number of members per family
  static const int maxMembersPerFamily = 50;
  
  /// Invite code length
  static const int inviteCodeLength = 8;

  // ============================================================================
  // Task Configuration
  // ============================================================================
  
  /// Maximum number of tasks per family
  static const int maxTasksPerFamily = 1000;
  
  /// Task priority levels
  static const List<String> taskPriorityLevels = [
    'low',
    'medium',
    'high',
    'urgent',
  ];

  // ============================================================================
  // Grocery Configuration
  // ============================================================================
  
  /// Maximum grocery list items
  static const int maxGroceryItems = 200;
  
  /// Maximum grocery item name length
  static const int maxGroceryItemNameLength = 100;

  // ============================================================================
  // Cache & Storage
  // ============================================================================
  
  /// Cache duration for user data
  static const Duration userDataCacheDuration = Duration(minutes: 5);
  
  /// Cache duration for family data
  static const Duration familyDataCacheDuration = Duration(minutes: 10);
  
  /// Maximum cache size in bytes (50MB)
  static const int maxCacheSize = 50 * 1024 * 1024;

  // ============================================================================
  // Feature Flags
  // ============================================================================
  
  /// Enable analytics (set via environment variable)
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );
  
  /// Enable crash reporting
  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: true,
  );
  
  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: false,
  );

  // ============================================================================
  // Date & Time Formats
  // ============================================================================
  
  /// Date format for display
  static const String dateFormat = 'MMM dd, yyyy';
  
  /// Time format for display
  static const String timeFormat = 'hh:mm a';
  
  /// Date and time format
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  
  /// Short date format
  static const String shortDateFormat = 'MM/dd/yyyy';
  
  /// ISO date format
  static const String isoDateFormat = 'yyyy-MM-dd';
  
  /// ISO datetime format
  static const String isoDateTimeFormat = 'yyyy-MM-ddTHH:mm:ssZ';

  // ============================================================================
  // Error Messages (Fallback - prefer localization)
  // ============================================================================
  
  /// Generic error message
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  
  /// Network error message
  static const String networkErrorMessage = 'No internet connection. Please check your network.';
  
  /// Timeout error message
  static const String timeoutErrorMessage = 'Request timed out. Please try again.';
  
  /// Unauthorized error message
  static const String unauthorizedErrorMessage = 'You are not authorized to perform this action.';
  
  /// Not found error message
  static const String notFoundErrorMessage = 'The requested resource was not found.';

  // ============================================================================
  // Success Messages (Fallback - prefer localization)
  // ============================================================================
  
  /// Generic success message
  static const String genericSuccessMessage = 'Operation completed successfully.';
  
  /// Profile updated message
  static const String profileUpdatedMessage = 'Profile updated successfully.';
  
  /// Event created message
  static const String eventCreatedMessage = 'Event created successfully.';
  
  /// Event updated message
  static const String eventUpdatedMessage = 'Event updated successfully.';
  
  /// Event deleted message
  static const String eventDeletedMessage = 'Event deleted successfully.';

  // ============================================================================
  // Route Names (Use with go_router)
  // ============================================================================
  
  /// Route paths - use these instead of hardcoding routes
  static const String routeSplash = '/splash';
  static const String routeWelcome = '/welcome';
  static const String routeAuth = '/auth';
  static const String routeSignUp = '/auth/sign-up';
  static const String routeSignIn = '/auth';
  static const String routeConsent = '/consent';
  static const String routeHome = '/home';
  static const String routeProfile = '/profile';
  static const String routeEditProfile = '/profile/edit';
  static const String routeCalendar = '/calendar';
  static const String routeTasks = '/tasks';
  static const String routeCreateTask = '/tasks/create';
  static const String routeEditTask = '/tasks/edit';
  static const String routeGroceries = '/groceries';
  static const String routeGroceryTemplatesManage = '/grocery-templates/manage';
  static const String routeFamilySelection = '/family-selection';
  static const String routeGetStarted = '/get-started';
  static const String routeFamilySetup = '/family-setup';
  static const String routeCreateFamily = '/family-setup/create';
  static const String routeJoinFamily = '/family-setup/join';
  static const String routeFamilySettings = '/family-settings';
  static const String routeSettings = '/settings';
  static const String routeHelp = '/help';
  static const String routeLeaderboard = '/leaderboard';
  static const String routePointsHistory = '/points-history';

  // ============================================================================
  // Animation Durations
  // ============================================================================
  
  /// Splash screen animation duration
  static const Duration splashAnimationDuration = Duration(seconds: 2);
  
  /// Splash screen display duration before navigation
  static const Duration splashDisplayDuration = Duration(seconds: 5);
  
  /// Fade animation interval start
  static const double fadeAnimationStart = 0.0;
  
  /// Fade animation interval end
  static const double fadeAnimationEnd = 0.6;
  
  /// Fade animation end value
  static const double fadeAnimationEndValue = 1.0;
  
  /// Scale animation interval start
  static const double scaleAnimationStart = 0.2;
  
  /// Scale animation interval end
  static const double scaleAnimationEnd = 0.8;
  
  /// Scale animation begin value
  static const double scaleAnimationBegin = 0.5;
  
  /// Scale animation end value
  static const double scaleAnimationEndValue = 1.0;
}

