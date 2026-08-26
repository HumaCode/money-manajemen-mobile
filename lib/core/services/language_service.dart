import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _keyLanguage = 'app_language_code';

  /// Get current saved language code ('id' or 'en')
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'id';
  }

  /// Save language code preference ('id' or 'en')
  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, code);
  }

  /// Check if current language is Indonesian
  static Future<bool> isIndonesian() async {
    final lang = await getLanguage();
    return lang == 'id';
  }

  /// Quick translation helper for Indonesian (idText) vs English (enText)
  static String tr(String idText, String enText, String currentLang) {
    return currentLang == 'en' ? enText : idText;
  }

  /// Available supported languages list
  static const List<Map<String, String>> supportedLanguages = [
    {
      'code': 'id',
      'name': 'Bahasa Indonesia',
      'flag': '🇮🇩',
      'subtitle': 'Bahasa Utama',
    },
    {
      'code': 'en',
      'name': 'English (US)',
      'flag': '🇬🇧',
      'subtitle': 'International English',
    },
  ];
}
