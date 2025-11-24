/// Supabase configuration for MyFamily app
class SupabaseConfig {

  
  // TODO: Replace with your actual Supabase project URL and anon key
  // Get these from https://supabase.com/dashboard/project/_/settings/api
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vovfhxnmiximhzdjadvu.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'REMOVED_SECRET',
  );
  
  /// Whether deep linking is enabled for OAuth flows
  static const bool enableDeepLinks = true;
  
  /// Deep link scheme for the app
  static const String deepLinkScheme = 'myfamily';
  
  /// Deep link host for authentication callbacks
  static const String deepLinkHost = 'auth-callback';
}

