/// Runtime configuration. Values are injected with `--dart-define` so that no
/// secret is ever committed. The anon key is safe to ship; RLS enforces access.
abstract final class AppConfig {
  static const appName = 'ReLearn';
  static const tagline = 'Recycle to Learn.';
  static const version = '0.1.0';

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Demo mode is on until Supabase credentials are provided.
  static bool get demoMode =>
      const bool.fromEnvironment('DEMO_MODE', defaultValue: true) ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey.isEmpty;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
