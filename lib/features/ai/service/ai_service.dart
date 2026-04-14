import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/chat_message.dart';

class AIService {
  // Base URL de tu API en Render
  final String _baseUrl = 'https://daiko-ai.onrender.com/ai';

  /// 1. ENVIAR MENSAJE (POST)
  /// Envía la pregunta, el historial de la sesión y el ID de sesión activo.
  Future<ChatMessage> sendMessageToDaiko({
    required String prompt,
    required String token,
    required List<ChatMessage> history,
    required String sessionId,
  }) async {
    final url = Uri.parse('$_baseUrl/consultar');

    try {
      // Preparamos el historial para que Gemini lo entienda (User/Model)
      final lastMessages = history
          .take(5)
          .map((m) => {
                "role": m.sender == MessageSender.user ? "user" : "model",
                "content": m.text
              })
          .toList();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "pregunta": prompt,
          "session_id": sessionId, // Enviamos el ID para evitar el NULL en la DB
          "historial": lastMessages,
          "contexto_gastos": [], // Aquí el backend ya jalará los datos de SQLAlchemy
          "user_name": "Kevin"
        }),
      ).timeout(const Duration(seconds: 25));

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

  /// 2. OBTENER SESIONES (GET)
  /// Trae la lista de chats previos para mostrar en el Drawer (menú lateral).
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

  /// 3. OBTENER HISTORIAL DE UNA SESIÓN (GET)
  /// Carga los mensajes guardados de un chat específico.
  Future<List<ChatMessage>> getHistoryBySession(String sessionId, String token) async {
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
            text: m['ai_response'], // Mapeamos la respuesta de la DB
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