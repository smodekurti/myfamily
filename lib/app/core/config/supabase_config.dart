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
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvdmZoeG5taXhpbWh6ZGphZHZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0MTMxMDUsImV4cCI6MjA3NTk4OTEwNX0.-iUAJjbjlzpyEF961n4bmvznFXtkx2S4WftDNNy2Vvg',
  );
  
  /// Whether deep linking is enabled for OAuth flows
  static const bool enableDeepLinks = true;
  
  /// Deep link scheme for the app
  static const String deepLinkScheme = 'myfamily';
  
  /// Deep link host for authentication callbacks
  static const String deepLinkHost = 'auth-callback';
}

