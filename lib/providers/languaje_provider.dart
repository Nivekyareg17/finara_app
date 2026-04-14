import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'es';
  bool _isInitialized = false; // El guardián de la carga

  // Getters seguros
  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;
  Locale get currentLocale => Locale(_currentLanguage);

  // Mapa de los 50 idiomas soportados (Tu lista original intacta)
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

  String get currentLanguageName => supportedLanguages[_currentLanguage] ?? 'Español';

  // Kevin: Quitamos la lógica del constructor para controlarla manualmente
  LanguageProvider();

  // 1. FUNCIÓN MAESTRA DE INICIALIZACIÓN
  // Esta es la que llamarás en el FutureBuilder de tus pantallas
  Future<void> ensureInitialized() async {
    if (_isInitialized) return; // Si ya cargó, no hace nada (velocidad pura)

    try {
      final prefs = await SharedPreferences.getInstance();
      // Usamos un valor por defecto seguro para evitar el Null Check Error
      _currentLanguage = prefs.getString('language') ?? 'es';
    } catch (e) {
      debugPrint("Error cargando idioma: $e");
      _currentLanguage = 'es';
    } finally {
      _isInitialized = true;
      notifyListeners(); // Avisamos que los datos ya están en memoria
    }
  }

  // Traducción usando tu servicio existente
  Future<String> translate(String text) async {
    if (text.isEmpty) return "";
    return await TranslationService.translate(text, _currentLanguage);
  }

  // Cambiar idioma y guardar en disco
  void setLanguage(String lang) async {
    if (_currentLanguage == lang) return;
    
    _currentLanguage = lang;
    notifyListeners(); 
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  // Método de carga interno por si acaso (compatibilidad)
  void _loadLanguage() async {
    await ensureInitialized();
  }
}