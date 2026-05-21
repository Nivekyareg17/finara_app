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
    List<Map<String, dynamic>> contextoGastos = const [],
  }) async {
    final url = Uri.parse('$_baseUrl/consultar');

    try {
      final lastMessages = history
          .take(5)
          .map((m) => {
                "role": m.sender == MessageSender.user ? "user" : "model",
                "content": m.text,
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
              "session_id": sessionId,
              "historial": lastMessages,
              "contexto_gastos": contextoGastos,
              "user_name": "Kevin",
              "tool": tool,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage(
          text: data['text'] ?? 'Sin respuesta de Daiko.',
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
        text: "Error de conexión: Verifica si el servidor está activo.",
        sender: MessageSender.daiko,
        timestamp: DateTime.now(),
      );
    }
  }

  // Carga las transacciones del usuario y las convierte al formato que necesita DAIKO
  Future<List<Map<String, dynamic>>> obtenerGastosParaDaiko(String token) async {
    final url = Uri.parse('https://finara-api-1lmd.onrender.com/transactions/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transacciones = jsonDecode(response.body);
        return transacciones
            .map((t) => {
                  "item": t["description"] ?? "Sin descripción",
                  "valor": t["amount"] ?? 0,
                  "tipo": t["type"] ?? "gasto",
                  "fecha": t["date"] ?? "",
                })
            .toList()
            .cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Error cargando transacciones para DAIKO: $e");
    }
    return [];
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((m) {
          return ChatMessage(
            text: m['ai_response'] ?? '',
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