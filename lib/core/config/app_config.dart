/// Runtime configuration. Values are injected with `--dart-define` or
/// `--dart-define-from-file` so that no secret is ever committed.
///
/// The publishable/anon key is safe to ship because Row Level Security
/// enforces access. Never pass the secret/service-role key to the app.
abstract final class AppConfig {
  static const appName = 'ReLearn';
  static const tagline = 'Recycle to Learn.';
  static const version = '0.4.0';

  /// The app locks after this much inactivity in live mode.
  static const sessionIdleTimeout = Duration(minutes: 15);

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Live mode turns on automatically when credentials are present. Set
  /// `DEMO_MODE=true` to force the in-memory store even with credentials.
  static bool get demoMode =>
      !hasSupabase || const bool.fromEnvironment('DEMO_MODE');
}
