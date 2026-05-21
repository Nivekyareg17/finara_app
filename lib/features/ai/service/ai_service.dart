import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/chat_message.dart';

class AIService {
  final String _baseUrl = 'https://daiko-ai.onrender.com/ai';

  // ──────────────────────────────────────────────
  // ENVIAR MENSAJE A DAIKO
  // ──────────────────────────────────────────────
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
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

  // ──────────────────────────────────────────────
  // OBTENER GASTOS/TRANSACCIONES PARA CONTEXTO
  // ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> obtenerGastosParaDaiko(
      String token) async {
    final url =
        Uri.parse('https://finara-api-1lmd.onrender.com/transactions/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transacciones =
            jsonDecode(utf8.decode(response.bodyBytes));
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

  // ──────────────────────────────────────────────
  // OBTENER LISTA DE SESIONES
  // ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSessions(String token) async {
    final url = Uri.parse('$_baseUrl/sessions');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
            jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      print("Error cargando sesiones: $e");
    }
    return [];
  }

  // ──────────────────────────────────────────────
  // OBTENER HISTORIAL DE UNA SESIÓN
  // Reconstruye tanto mensajes del usuario como de Daiko
  // ──────────────────────────────────────────────
  Future<List<ChatMessage>> getHistoryBySession(
      String sessionId, String token) async {
    final url = Uri.parse('$_baseUrl/historial/$sessionId');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));

        final List<ChatMessage> mensajes = [];

        for (final m in data) {
          // Mensaje del usuario (si existe en el registro)
          if (m['user_message'] != null &&
              (m['user_message'] as String).isNotEmpty) {
            mensajes.add(ChatMessage(
              text: m['user_message'],
              sender: MessageSender.user,
              timestamp: DateTime.tryParse(m['created_at'] ?? '') ??
                  DateTime.now(),
            ));
          }

          // Respuesta de Daiko
          if (m['ai_response'] != null &&
              (m['ai_response'] as String).isNotEmpty) {
            mensajes.add(ChatMessage(
              text: m['ai_response'],
              sender: MessageSender.daiko,
              timestamp: DateTime.tryParse(m['created_at'] ?? '') ??
                  DateTime.now(),
            ));
          }
        }

        // El ListView es reverse:true, así que invertimos el orden
        return mensajes.reversed.toList();
      }
    } catch (e) {
      print("Error cargando mensajes de la sesión: $e");
    }
    return [];
  }

  // ──────────────────────────────────────────────
  // ELIMINAR UNA SESIÓN Y SU HISTORIAL
  // ──────────────────────────────────────────────
  Future<bool> deleteSession(String sessionId, String token) async {
    final url = Uri.parse('$_baseUrl/sessions/$sessionId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      // 200 OK o 204 No Content = éxito
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print(
            "Error eliminando sesión: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión al eliminar sesión: $e");
      return false;
    }
  }
}