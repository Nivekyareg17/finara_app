enum MessageType { text, image, analysis }
// ⚠️ CAMBIO: Usamos 'daiko' en lugar de 'ai'
enum MessageSender { user, daiko } 

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final String? imageUrl;     
  final MessageType type;     
  
  final String? trend;        
  final String? rsiLevel;     

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.imageUrl,
    this.type = MessageType.text,
    this.trend,
    this.rsiLevel,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      // ⚠️ IMPORTANTE: Si viene de la IA, le asignamos 'daiko'
      sender: json['sender'] == 'user' ? MessageSender.user : MessageSender.daiko,
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