/// Supabase configuration for MyFamily app
class SupabaseConfig {

  
  // Supply these with --dart-define or CI build settings.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  
  /// Whether deep linking is enabled for OAuth flows
  static const bool enableDeepLinks = true;
  
  /// Deep link scheme for the app
  static const String deepLinkScheme = 'myfamily';
  
  /// Deep link host for authentication callbacks
  static const String deepLinkHost = 'auth-callback';
}

