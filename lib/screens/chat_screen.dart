import 'dart:async';

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
  final scrollController = ScrollController();
  final controller = TextEditingController();

  StreamSubscription? periodicRefresh;
  List messages = [];
  bool isLoading = true;
  bool isSending = false;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    loadBlockStatus();
    loadMessages(showLoader: true);
    periodicRefresh = Stream.periodic(const Duration(seconds: 4)).listen((_) {
      loadMessages();
    });
  }

  Future<void> loadBlockStatus() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;

    final blocked = await ApiService.isUserBlocked(token, widget.userId);
    if (!mounted) return;
    setState(() => isBlocked = blocked);
  }

  @override
  void dispose() {
    periodicRefresh?.cancel();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  String formatTimestamp(DateTime? date) {
    if (date == null) return "";

    final now = DateTime.now();
    final time = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return "Hoy $time";
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return "Ayer $time";
    }

    return "${date.day}/${date.month} $time";
  }

  DateTime? parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString().replaceFirst(" ", "T")).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> loadMessages({bool showLoader = false}) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        messages = [];
        isLoading = false;
      });
      return;
    }

    if (showLoader && mounted) {
      setState(() => isLoading = true);
    }

    final data = await ApiService.getMessages(token, widget.userId);
    if (!mounted) return;

    setState(() {
      messages = data.reversed.toList();
      isLoading = false;
    });
  }

  Future<void> sendMessage() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final text = controller.text.trim();

    if (token == null || token.isEmpty || text.isEmpty || isSending || isBlocked) {
      return;
    }

    setState(() => isSending = true);
    controller.clear();

    final success = await ApiService.sendMessage(token, widget.userId, text);
    if (!mounted) return;

    setState(() => isSending = false);

    if (success) {
      await loadMessages();
    } else {
      controller.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo enviar el mensaje")),
      );
    }
  }

  Future<void> toggleBlock() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;

    final success = isBlocked
        ? await ApiService.unblockUser(token, widget.userId)
        : await ApiService.blockUser(token, widget.userId);

    if (!mounted) return;

    if (success) {
      setState(() => isBlocked = !isBlocked);
      await loadMessages();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (isBlocked ? "Usuario bloqueado" : "Usuario desbloqueado")
              : "No se pudo actualizar el bloqueo",
        ),
      ),
    );
  }

  Widget buildMessageBubble(Map msg, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = parseDate(msg["timestamp"]);
    final bubbleColor = isMe
        ? const Color(0xFF087F5B)
        : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9));
    final textColor = isMe ? Colors.white : (isDark ? Colors.white : Colors.black87);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (msg["content"] ?? "").toString(),
                style: TextStyle(color: textColor, height: 1.25),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatTimestamp(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 5),
                    Icon(
                      msg["is_read"] == true ? Icons.done_all : Icons.done,
                      size: 14,
                      color: msg["is_read"] == true
                          ? const Color(0xFF9AE6B4)
                          : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFF087F5B).withOpacity(0.12),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF087F5B),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Empieza la conversacion con ${widget.userName}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              "Tus mensajes apareceran aqui.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : "?";

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF087F5B),
              child: Text(initial, style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName),
                Text(
                  "Chat privado",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) => toggleBlock(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "block",
                child: Row(
                  children: [
                    Icon(
                      isBlocked ? Icons.lock_open : Icons.block,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(isBlocked ? "Desbloquear" : "Bloquear"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? buildEmptyState()
                      : ListView.builder(
                          controller: scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = Map<String, dynamic>.from(messages[index]);
                            final isMe = msg["sender_id"] != widget.userId;
                            return buildMessageBubble(msg, isMe);
                          },
                        ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !isBlocked,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: "Escribe un mensaje...",
                        helperText: isBlocked
                            ? "Desbloquea este chat para enviar mensajes"
                            : null,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: isSending || isBlocked ? null : sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSending
                            ? Colors.grey.shade400
                            : const Color(0xFF087F5B),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
