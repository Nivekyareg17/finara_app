import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/chat_message.dart';

class AIService {
  // Asegúrate de que la URL sea exactamente esta
  final String _urlBase = 'https://daiko-ai.onrender.com/ai/consultar';

  Future<ChatMessage> sendMessageToDaiko(
    String prompt, 
    String token, 
    List<ChatMessage> history // <--- Agregamos el historial
  ) async {
    
    // MOCK DATA: Para que Daiko analice algo aunque falle el registro real
    final List<Map<String, dynamic>> mockGastos = [
      {"item": "Gasolina Kia Picanto", "valor": 85000, "cat": "Transporte"},
      {"item": "Goyurt", "valor": 14000, "cat": "Gasto Hormiga"},
      {"item": "Netflix", "valor": 45000, "cat": "Suscripciones"},
    ];

    try {
      // 1. Preparamos el historial (Role model para la IA, user para ti)
      final lastMessages = history.take(5).map((m) => {
        "role": m.sender == MessageSender.user ? "user" : "model",
        "content": m.text
      }).toList();

      // 2. CAMBIO CLAVE: Usamos http.post y enviamos JSON
      final response = await http.post(
        Uri.parse(_urlBase),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "pregunta": prompt,
          "historial": lastMessages,
          "contexto_gastos": mockGastos,
          "user_name": "Kevin"
        }),
      ).timeout(const Duration(seconds: 20)); // Tiempo de espera para Render

      print("DEBUG STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage(
          text: data['text'] ?? 'Sin respuesta de Daiko',
          sender: MessageSender.daiko,
          timestamp: DateTime.now(),
        );
      } else {
        return ChatMessage(
          text: "Error del servidor (${response.statusCode}): ${response.body}",
          sender: MessageSender.daiko,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print("DEBUG FATAL ERROR: $e");
      return ChatMessage(
        text: "Error de conexión: Verifica que Render esté encendido, Kevin.",
        sender: MessageSender.daiko,
        timestamp: DateTime.now(),
      );
    }
  }
}