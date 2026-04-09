import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // Librería para la animación
import '../model/chat_message.dart';
import '../service/ai_service.dart';
import '../../../widgets/custom_bottom_nav.dart';

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

  final Color primaryGreen = const Color(0xFF10B981);
  final Color accentGreen = const Color(0xFF059669);

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final aiBubbleColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFECFDF5);
    final userBubbleColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Scaffold(
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
                return msg.sender == MessageSender.user
                    ? _buildUserMessage(msg, isDark, userBubbleColor)
                    : _buildDaikoMessage(msg, isDark, aiBubbleColor);
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

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? const Color(0xFF0F172A).withOpacity(0.8)
          : Colors.white.withOpacity(0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          _buildDaikoAvatar(size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "DAIKO AI",
                style: TextStyle(
                  color: Color.fromARGB(255, 10, 109, 82),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "ACTIVE INTELLIGENCE",
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.info_outline,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        )
      ],
    );
  }

  Widget _buildUserMessage(
      ChatMessage msg, bool isDark, Color userBubbleColor) {
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
        child: Text(
          msg.text,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF334155),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDaikoMessage(ChatMessage msg, bool isDark, Color aiBubbleColor) {
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
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                border: Border.all(
                  color: primaryGreen.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INTEGRACIÓN DE LA ANIMACIÓN TIPO MÁQUINA DE ESCRIBIR
                  DefaultTextStyle(
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          msg.text,
                          speed: const Duration(milliseconds: 30), // Velocidad de escritura
                        ),
                      ],
                      totalRepeatCount: 1, // Solo se anima una vez
                      displayFullTextOnTap: true, // Muestra todo si el usuario toca la burbuja
                      stopPauseOnTap: true,
                    ),
                  ),
                  if (msg.type == MessageType.analysis)
                    _buildAnalysisCard(msg, isDark),
                ],
              ),
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
        gradient: LinearGradient(
          colors: [primaryGreen, accentGreen],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: iconSize),
    );
  }

  Widget _buildAnalysisCard(ChatMessage msg, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildMetric("TENDENCIA", msg.trend ?? "Bullish",
                  Icons.trending_up, primaryGreen, isDark),
              const SizedBox(width: 12),
              _buildMetric("RSI LEVEL", msg.rsiLevel ?? "62.4", Icons.speed,
                  Colors.amber, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                )),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _buildQuickAction("Photo", Icons.image, isDark),
              const SizedBox(width: 12),
              _buildQuickAction("Video", Icons.videocam, isDark),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.add, color: primaryGreen),
                    hintText: "Ask DAIKO anything...",
                    hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: IconButton(
                    onPressed: _sendMessage,
                    // CAMBIADO: Ahora muestra el icono de ENVIAR en lugar de micrófono
                    icon: const Icon(Icons.send, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryGreen),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              )),
        ],
      ),
    );
  }
}
