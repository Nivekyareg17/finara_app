import 'package:flutter/material.dart';
import '../model/chat_message.dart';
import '../service/ai_service.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  bool _isLoading = false;

  // --- MÉTODOS DE LÓGICA ---

  void _sendMessage() async {
  if (_controller.text.isEmpty) return;

  final userMsg = ChatMessage(
    text: _controller.text,
    sender: MessageSender.user,
    timestamp: DateTime.now(),
  );

  if (!mounted) return;

  setState(() {
    _messages.insert(0, userMsg);
    _isLoading = true;
  });

  _controller.clear();

  try {
    final response = await _aiService.sendMessageToDaiko(userMsg.text);

    if (!mounted) return;

    setState(() {
      _messages.insert(0, response);
      _isLoading = false;
    });

  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }
}

  // --- DISEÑO PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Para que los mensajes nuevos salgan abajo
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg.sender == MessageSender.user) {
                  return _buildUserMessage(msg);
                } else {
                  return _buildDaikoMessage(msg);
                }
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(color: Color(0xFF2ECC71)),
          _buildInputSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- COMPONENTES QUE FALTABAN (SOLUCIÓN A LOS ERRORES) ---

  Widget _buildUserMessage(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 50),
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Color(0xFFF4FBF7),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          ),
        ),
        child: Text(msg.text, style: const TextStyle(color: Color(0xFF2C3E50))),
      ),
    );
  }

  Widget _buildDaikoMessage(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFE8F8F1),
            child: Icon(Icons.auto_awesome, size: 15, color: Color(0xFF2ECC71)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.text, style: const TextStyle(color: Color(0xFF2C3E50))),
                  if (msg.type == MessageType.analysis) _buildAnalysisCard(msg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildMetricTile("TENDENCIA", msg.trend ?? "Neutral", Icons.trending_up, Colors.green),
              const SizedBox(width: 10),
              _buildMetricTile("RSI", msg.rsiLevel ?? "50.0", Icons.speed, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF2F3F4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE APOYO ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text("DAIKO IA", style: TextStyle(color: Colors.black, fontSize: 16)),
      centerTitle: true,
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Pregunta a DAIKO...",
                filled: true,
                fillColor: const Color(0xFFF8F9F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF2ECC71)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      selectedItemColor: const Color(0xFF2ECC71),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Ideas"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
      ],
    );
  }
}