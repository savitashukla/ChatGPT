class AppConstants {
  /// To get OpenAI Api Key, go to https://beta.openai.com/account/api-keys
  /// To get Gemini API Key, go to https://aistudio.google.com/app/apikey
  ///
  /// Usage:
  /// For development: flutter run --dart-define=OPENAI_API_KEY=your_key --dart-define=GEMINI_API_KEY=your_key
  /// For release: Add keys to your CI/CD environment variables

  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // Gemini API configuration
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.5-flash'; // Updated to available model

  // Validation methods
  static bool get isOpenAiKeyValid => openAiApiKey.isNotEmpty;
  static bool get isGeminiKeyValid => geminiApiKey.isNotEmpty;

  static void validateApiKeys() {
    if (!isOpenAiKeyValid) {
      throw Exception('OpenAI API key is missing. Please provide OPENAI_API_KEY via --dart-define');
    }
    if (!isGeminiKeyValid) {
      throw Exception('Gemini API key is missing. Please provide GEMINI_API_KEY via --dart-define');
    }
  }

  // Legacy support - deprecated
  @Deprecated('Use openAiApiKey instead')
  static String get apiKey => openAiApiKey;
}