import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/chat_message.dart';

class AIService {

  final String _urlBase = 'https://daiko-ai.onrender.com/ai/consultar';

  Future<ChatMessage> sendMessageToDaiko(String prompt) async {
    try {
      final url = Uri.parse('$_urlBase?pregunta=${Uri.encodeComponent(prompt)}');
      final response = await http.get(url);

      print("DEBUG: Status Code: ${response.statusCode}");
      print("DEBUG: Cuerpo recibido: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return ChatMessage(
          // Buscamos 'text' porque así lo configuramos en Python
          text: data['text'] ?? 'Sin respuesta en el JSON', 
          // ⚠️ CORREGIDO: Debe coincidir con el nombre de tu enum (daiko o ai)
          sender: MessageSender.daiko, 
          timestamp: DateTime.now(),
        );
      } else {
        return ChatMessage(
          text: 'Error del servidor: ${response.statusCode}',
          sender: MessageSender.daiko,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print("DEBUG: Error de conexión -> $e");
      return ChatMessage(
        text: 'Error de conexión: $e',
        sender: MessageSender.daiko,
        timestamp: DateTime.now(),
      );
    }
  }
}
