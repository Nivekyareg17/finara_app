import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/chat_message.dart';

class AIService {
  final String _apiKey = 'TU_API_KEY_AQUI'; 
  final String _url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<ChatMessage> sendMessageToDaiko(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_url?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "Eres Daiko, IA de la app Finara. Analiza el siguiente mensaje. "
                          "Si es una consulta financiera, responde en formato JSON con estos campos: "
                          "{ 'text': 'tu respuesta', 'trend': 'Alcista/Bajista/Neutral', 'rsi': 'valor', 'type': 'analysis' }. "
                          "Si es charla normal, usa type: 'text'. "
                          "Mensaje del usuario: $prompt"
                }
              ]
            }
          ],
          // Esto le indica a Gemini que responda en formato JSON puro
          "generationConfig": {
            "responseMimeType": "application/json"
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String jsonRaw = data['candidates'][0]['content']['parts'][0]['text'];
        final Map<String, dynamic> aiJson = jsonDecode(jsonRaw);

        return ChatMessage(
          text: aiJson['text'] ?? '',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          trend: aiJson['trend'],
          rsiLevel: aiJson['rsi'],
          type: aiJson['type'] == 'analysis' ? MessageType.analysis : MessageType.text,
        );
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en Daiko Service: $e');
    }
  }
}