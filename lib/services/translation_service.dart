import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  static Future<String> translate(String text, String targetLangCode) async {
    if (text.isEmpty || targetLangCode == 'es') return text;

    final targetLanguage = _mapLanguage(targetLangCode);
    
    // 1. Instanciamos el traductor
    final onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.spanish,
      targetLanguage: targetLanguage,
    );

    try {
      final modelManager = OnDeviceTranslatorModelManager();
      
      // 2. IMPORTANTE: Usamos el objeto de idioma directamente para verificar
      final bool isDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);
      
      if (!isDownloaded) {
        print('Descargando modelo para: $targetLangCode...');
        // Esperamos a que la descarga termine antes de seguir
        await modelManager.downloadModel(targetLanguage.bcpCode);
        print('Descarga completada.');
      }

      // 3. Traducimos
      final translatedText = await onDeviceTranslator.translateText(text);
      
      onDeviceTranslator.close();
      return translatedText;
    } catch (e) {
      print('Error en traducción a $targetLangCode: $e');
      onDeviceTranslator.close(); // Siempre cerrar incluso si hay error
      return text; 
    }
  }

  static TranslateLanguage _mapLanguage(String code) {
    // ML Kit a veces usa códigos de 2 letras (en) o 3 (eng). 
    // Este método busca la mejor coincidencia.
    return TranslateLanguage.values.firstWhere(
      (lang) => lang.bcpCode == code || lang.name == code,
      orElse: () => TranslateLanguage.english,
    );
  }
}