class AppEnv {
  // Supabase: OK to be public (anon key is designed for client use with RLS).
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // AI keys: NOT secure in a Flutter client (web/mobile/desktop). Treat as public.
  // Prefer moving these calls to a backend/Edge Function.
  static const String deepseekBaseUrl = String.fromEnvironment(
    'DEEPSEEK_BASE_URL',
    defaultValue: 'https://api.deepseek.com/chat/completions',
  );
  static const String deepseekApiKey =
      String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: '');

  static const String huggingfaceBaseUrl = String.fromEnvironment(
    'HUGGINGFACE_BASE_URL',
    defaultValue: 'https://router.huggingface.co/models',
  );
  static const String huggingfaceApiKey =
      String.fromEnvironment('HUGGINGFACE_API_KEY', defaultValue: '');
  static const String huggingfaceDefaultModel = String.fromEnvironment(
    'HUGGINGFACE_DEFAULT_MODEL',
    defaultValue: 'MiniMaxAI/MiniMax-M2.1',
  );

  static void assertRequired() {
    final missing = <String>[];
    if (supabaseUrl.trim().isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.trim().isEmpty) missing.add('SUPABASE_ANON_KEY');

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required build-time environment variables: ${missing.join(', ')}. '
        'Provide them via --dart-define (or Docker build args).',
      );
    }
  }
}
