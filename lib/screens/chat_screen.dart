import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List messages = [];

  @override
  void initState() {
    super.initState();

    loadMessages();

    //auto refresco
    Future.delayed(Duration.zero, () {
      startAutoRefresh();
    });
  }

  late final periodicRefresh;

  void startAutoRefresh() {
    periodicRefresh = Stream.periodic(const Duration(seconds: 3)).listen((_) {
      loadMessages();
    });
  }

  @override
  void dispose() {
    periodicRefresh.cancel();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Widget buildMessageBubble(msg, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final raw = msg["timestamp"];
    final date = raw != null
        ? DateTime.parse(raw.replaceFirst(" ", "T") + "Z").toLocal()
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [
                          Colors.green.shade500,
                          Colors.green.shade700,
                        ],
                      )
                    : null,
                color: isMe
                    ? null
                    : (isDark ? Colors.grey.shade800 : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg["content"],
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTimestamp(date),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      if (isMe) const SizedBox(width: 4),
                      if (isMe)
                        Icon(
                          msg["is_read"] == true ? Icons.done_all : Icons.done,
                          size: 14,
                          color: msg["is_read"] == true
                              ? Colors.blueAccent
                              : Colors.white70,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final scrollController = ScrollController();
  final controller = TextEditingController();
  String formatTimestamp(DateTime? date) {
    if (date == null) return "";

    final now = DateTime.now();

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return "Hoy ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return "Ayer ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future<void> loadMessages() async {
    final auth = context.read<AuthProvider>();
    final data = await ApiService.getMessages(auth.token!, widget.userId);

    setState(() {
      messages = data.reversed.toList();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green.shade600,
              child: Text(
                widget.userName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: const TextStyle(fontSize: 16)),
                const Text(
                  "En línea",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          //MNSJ
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final isMe = msg["sender_id"] != widget.userId;

                return TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: buildMessageBubble(msg, isMe),
                  ),
                );
              },
            ),
          ),

          //INPUT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  // CAJA DE TEXTO
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4, // permite crecer como WhatsApp
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Escribe un mensaje...",
                          border: InputBorder.none,

                          // ICONO IZQUIERDA (opcional)
                          prefixIcon: Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // BOTÓN ENVIAR
                  GestureDetector(
                    onTap: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;

                      controller.clear();

                      await ApiService.sendMessage(
                        context.read<AuthProvider>().token!,
                        widget.userId,
                        text,
                      );

                      loadMessages();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade500,
                            Colors.green.shade700,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
