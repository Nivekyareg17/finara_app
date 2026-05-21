import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/chat_message.dart';

class AIService {
 
  final String _baseUrl = 'https://daiko-ai.onrender.com/ai';

  
  Future<ChatMessage> sendMessageToDaiko({
    required String prompt,
    required String token,
    required List<ChatMessage> history,
    required String sessionId,
    required String tool,
  }) async {
    final url = Uri.parse('$_baseUrl/consultar');

    try {
    
      final lastMessages = history
          .take(5)
          .map((m) => {
                "role": m.sender == MessageSender.user ? "user" : "model",
                "content": m.text
              })
          .toList();

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              "pregunta": prompt,
              "session_id":
                  sessionId, 
              "historial": lastMessages,
              "contexto_gastos":
                  [], 
              "user_name": "Kevin"
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage(
          text: data['text'] ?? 'Sin respuesta de Daiko',
          sender: MessageSender.daiko,
          timestamp: DateTime.now(),
        );
      } else {
        return ChatMessage(
          text: "Daiko tuvo un problema (${response.statusCode}).",
          sender: MessageSender.daiko,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return ChatMessage(
        text: "Error de conexión: Revisa si Render está activo.",
        sender: MessageSender.daiko,
        timestamp: DateTime.now(),
      );
    }
  }

  
  Future<List<Map<String, dynamic>>> getSessions(String token) async {
    final url = Uri.parse('$_baseUrl/sessions');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print("Error cargando sesiones: $e");
    }
    return [];
  }

  Future<List<ChatMessage>> getHistoryBySession(
      String sessionId, String token) async {
    final url = Uri.parse('$_baseUrl/historial/$sessionId');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((m) {
          return ChatMessage(
            text: m['ai_response'], 
            sender: MessageSender.daiko,
            timestamp: DateTime.parse(m['created_at']),
          );
        }).toList();
      }
    } catch (e) {
      print("Error cargando mensajes de la sesión: $e");
    }
    return [];
  }
}
