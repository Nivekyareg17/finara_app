enum MessageType { text, image, analysis }
enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final String? imageUrl;     // Para mostrar el gráfico de la imagen
  final MessageType type;     
  
  // Nuevos campos para el "Análisis de Daiko"
  final String? trend;        // Ej: "Alcista"
  final String? rsiLevel;     // Ej: "62.4 (Neutral)"

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.imageUrl,
    this.type = MessageType.text,
    this.trend,
    this.rsiLevel,
  });

  // Esto nos servirá cuando Gemini nos devuelva datos estructurados
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      sender: json['sender'] == 'user' ? MessageSender.user : MessageSender.ai,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
      imageUrl: json['imageUrl'],
      trend: json['trend'],
      rsiLevel: json['rsiLevel'],
      type: _parseType(json['type']),
    );
  }

  static MessageType _parseType(String? type) {
    switch (type) {
      case 'analysis': return MessageType.analysis;
      case 'image': return MessageType.image;
      default: return MessageType.text;
    }
  }
}