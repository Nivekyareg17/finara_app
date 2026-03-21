import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/chat_message.dart';

class AIService {
  // Ahora apuntamos a nuestro propio engine
  final String _urlBase = 'http://192.168.1.9:8000/ai/consultar';

  Future<ChatMessage> sendMessageToDaiko(String prompt) async {
    final response = await http.get(
      Uri.parse('$_urlBase?pregunta=${Uri.encodeComponent(prompt)}'),
    );

    if (response.statusCode == 200) {
      // Usamos el factory que ya creaste en tu modelo ChatMessage
      return ChatMessage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  }
}