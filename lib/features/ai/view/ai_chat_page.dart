import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../model/chat_message.dart';
import '../service/ai_service.dart';
import '../../../widgets/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

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

  // Kevin: ID de sesión actual (se inicializa con el tiempo actual)
  String _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

  final Color primaryGreen = const Color(0xFF10B981);
  final Color accentGreen = const Color(0xFF059669);

  // Cargar mensajes de una sesión específica desde el menú
  void _cargarSesion(String sessionId, String token) async {
    setState(() {
      _messages.clear();
      _isLoading = true;
      _currentSessionId = sessionId;
    });

    try {
      final historial = await _aiService.getHistoryBySession(sessionId, token);
      if (!mounted) return;
      setState(() {
        // Los insertamos al revés porque el ListView tiene reverse: true
        _messages.addAll(historial.reversed);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? userToken = authProvider.token;

    if (userToken == null) return;

    final userMsg = ChatMessage(
      text: _controller.text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMsg);
      _isLoading = true;
    });

    _controller.clear();

    try {
      // Enviamos el mensaje con el ID de sesión actual
      final response = await _aiService.sendMessageToDaiko(
        prompt: userMsg.text,
        token: userToken,
        history: _messages,
        sessionId: _currentSessionId,
      );

      if (!mounted) return;
      setState(() {
        _messages.insert(0, response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final String userToken = authProvider.token ?? "";

    final aiBubbleColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFECFDF5);
    final userBubbleColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Scaffold(
      // --- MENÚ LATERAL (DRAWER) ---
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryGreen, accentGreen]),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text("DAIKO HISTORY",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.add_comment, color: primaryGreen),
              title: const Text("Nueva Conversación",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                setState(() {
                  _messages.clear();
                  _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _aiService.getSessions(userToken),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No hay chats guardados"));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final session = snapshot.data![index];
                      // Usamos el session_id para mostrar algo (puedes usar session_title si lo agregaste)
                      return ListTile(
                        leading: const Icon(Icons.history, size: 20),
                        title: Text("Chat ${session['session_id'].toString().substring(0, 8)}...",
                            style: const TextStyle(fontSize: 14)),
                        onTap: () {
                          _cargarSesion(session['session_id'], userToken);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Container(
                  key: ValueKey(msg.timestamp.millisecondsSinceEpoch),
                  child: msg.sender == MessageSender.user
                      ? _buildUserMessage(msg, isDark, userBubbleColor)
                      : _buildDaikoMessage(msg, isDark, aiBubbleColor, index == 0),
                );
              },
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(
              color: primaryGreen,
              backgroundColor: isDark ? Colors.white10 : const Color(0xFFECFDF5),
            ),
          _buildInputSection(isDark),
        ],
      ),
    );
  }

  // --- LOS MÉTODOS DE UI SE MANTIENEN IGUALES ---

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F172A).withOpacity(0.8) : Colors.white.withOpacity(0.8),
      elevation: 0,
      iconTheme: IconThemeData(color: primaryGreen), // Para que el icono del Drawer sea verde
      title: Row(
        children: [
          _buildDaikoAvatar(size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("DAIKO AI",
                  style: TextStyle(color: Color.fromARGB(255, 10, 109, 82), fontWeight: FontWeight.w800, fontSize: 16)),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text("ACTIVE INTELLIGENCE",
                      style: TextStyle(color: primaryGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage msg, bool isDark, Color userBubbleColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 60),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: userBubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
        child: Text(msg.text,
            style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildDaikoMessage(ChatMessage msg, bool isDark, Color aiBubbleColor, bool isLast) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDaikoAvatar(size: 32, iconSize: 16),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: aiBubbleColor,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(20)),
                border: Border.all(color: primaryGreen.withOpacity(0.1)),
              ),
              child: isLast
                  ? AnimatedTextKit(
                      animatedTexts: [TypewriterAnimatedText(msg.text, speed: const Duration(milliseconds: 30))],
                      totalRepeatCount: 1,
                      displayFullTextOnTap: true,
                    )
                  : Text(msg.text,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaikoAvatar({required double size, double iconSize = 20}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryGreen, accentGreen], begin: Alignment.bottomLeft, end: Alignment.topRight),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: iconSize),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.add, color: primaryGreen),
                hintText: "Ask DAIKO anything...",
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}