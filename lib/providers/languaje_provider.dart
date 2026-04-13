import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart'; // Asegúrate de importar tu servicio

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'es';

  // 1. Mapa de los 50 idiomas soportados
  final Map<String, String> supportedLanguages = {
    'es': 'Español', 'en': 'English', 'fr': 'Français', 'de': 'Deutsch',
    'it': 'Italiano', 'pt': 'Português', 'ru': 'Русский', 'ja': '日本語',
    'ko': '한국어', 'zh': '中文', 'ar': 'العربية', 'hi': 'हिन्दी',
    'tr': 'Türkçe', 'nl': 'Nederlands', 'pl': 'Polski', 'sv': 'Svenska',
    'da': 'Dansk', 'no': 'Norsk', 'fi': 'Suomi', 'el': 'Ελληνικά',
    'he': 'עברית', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu',
    'th': 'ไทย', 'vi': 'Tiếng Việt', 'bn': 'বাংলা', 'gu': 'ગુજરાતી',
    'kn': 'ಕನ್ನಡ', 'mr': 'मराठी', 'ta': 'தமிழ்', 'te': 'తెలుగు',
    'ur': 'اردو', 'af': 'Afrikaans', 'be': 'Беларуская', 'bg': 'Български',
    'ca': 'Català', 'cs': 'Čeština', 'cy': 'Cymraeg', 'eo': 'Esperanto',
    'et': 'Eesti', 'fa': 'فارسی', 'ga': 'Gaeilge', 'gl': 'Galego',
    'hr': 'Hrvatski', 'hu': 'Magyar', 'is': 'Íslenska', 'lt': 'Lietuvių',
    'lv': 'Latviešu', 'mk': 'Македонски', 'ro': 'Română',
  };

  String get currentLanguage => _currentLanguage;


  String get currentLanguageName => supportedLanguages[_currentLanguage] ?? 'Español';

  LanguageProvider() {
    _loadLanguage();
  }

  
  Future<String> translate(String text) async {
    return await TranslationService.translate(text, _currentLanguage);
  }

  void setLanguage(String lang) async {
    if (_currentLanguage == lang) return;
    _currentLanguage = lang;
    notifyListeners(); 
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'es';
    notifyListeners();
  }
}