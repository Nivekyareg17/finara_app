import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'public_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String? userImageUrl;
  final String? userDescription;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    this.userDescription,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final scrollController = ScrollController();
  final controller = TextEditingController();

  List messages = [];
  bool isTyping = false;
  bool isBlockedByMe = false;
  bool isBlockedByOther = false;
  bool isLoadingBlock = true;
  Timer? periodicRefresh;

  @override
  void initState() {
    super.initState();
    loadMessages();
    loadBlockStatus();
    periodicRefresh = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!isBlockedByMe && !isBlockedByOther) loadMessages();
    });
  }

  @override
  void dispose() {
    periodicRefresh?.cancel();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  ImageProvider? get contactImageProvider {
    final rawUrl = widget.userImageUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith("http")) return NetworkImage(rawUrl);
    return NetworkImage(
      "${ApiService.baseUrl}${rawUrl.startsWith("/") ? "" : "/"}$rawUrl",
    );
  }

  String get contactInitial {
    final name = widget.userName.trim();
    return name.isEmpty ? "U" : name[0].toUpperCase();
  }

  void openContactProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: widget.userId,
          fallbackName: widget.userName,
          fallbackImageUrl: widget.userImageUrl,
          fallbackDescription: widget.userDescription,
        ),
      ),
    );
  }

  String formatTimestamp(DateTime? date) {
    if (date == null) return "";
    final now = DateTime.now();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return "Hoy $hour:$minute";
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return "Ayer $hour:$minute";
    }

    return "${date.day}/${date.month} $hour:$minute";
  }

  DateTime? parseMessageDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString().replaceFirst(" ", "T"));
  }

  Future<void> loadMessages() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final data = await ApiService.getMessages(token, widget.userId);
    if (!mounted) return;

    setState(() {
      messages = data.reversed.toList();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      if (scrollController.offset <= 100) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> loadBlockStatus() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final data = await ApiService.getBlockStatus(token, widget.userId);
    if (!mounted) return;

    setState(() {
      isBlockedByMe =
          data["blocked_by_me"] == true || data["is_blocked"] == true;
      isBlockedByOther =
          data["blocked_me"] == true || data["blocked_by_other"] == true;
      isLoadingBlock = false;
    });
  }

  Future<void> toggleBlock() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final wasBlocked = isBlockedByMe;
    setState(() => isLoadingBlock = true);

    final success = wasBlocked
        ? await ApiService.unblockUser(token, widget.userId)
        : await ApiService.blockUser(token, widget.userId);

    if (!mounted) return;

    if (success) {
      await loadBlockStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(wasBlocked ? "Contacto desbloqueado" : "Contacto bloqueado"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => isLoadingBlock = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo actualizar el bloqueo"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || isBlockedByMe || isBlockedByOther) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final success = await ApiService.sendMessage(token, widget.userId, text);
    if (!mounted) return;

    if (success) {
      controller.clear();
      setState(() => isTyping = false);
      await loadMessages();
    } else {
      await loadBlockStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo enviar el mensaje"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> sendQuickMessage(String text) async {
    controller.text = text;
    setState(() => isTyping = true);
    await sendMessage();
  }

  Widget quickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Colors.green.shade700),
      label: Text(label),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      side: BorderSide(
        color: isDark ? Colors.white10 : const Color(0xFFDCE7E2),
      ),
      onPressed: onTap,
    );
  }

  Widget buildMessageBubble(dynamic msg, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final raw = msg["timestamp"];
    final date = parseMessageDate(raw);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade700],
                  )
                : null,
            color: isMe ? null : (isDark ? Colors.grey.shade900 : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isMe ? const Radius.circular(18) : const Radius.circular(6),
              bottomRight:
                  isMe ? const Radius.circular(6) : const Radius.circular(18),
            ),
            border: isMe
                ? null
                : Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                msg["content"]?.toString() ?? "",
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
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
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg["is_read"] == true ? Icons.done_all : Icons.done,
                      size: 14,
                      color: msg["is_read"] == true
                          ? Colors.blueAccent
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

  Widget buildBlockBanner() {
    if (!isBlockedByMe && !isBlockedByOther) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title =
        isBlockedByMe ? "Contacto bloqueado" : "Chat no disponible";
    final subtitle = isBlockedByMe
        ? "No puedes enviar ni recibir mensajes de este usuario mientras este bloqueado."
        : "Este usuario no esta disponible para recibir mensajes en este momento.";
    final icon = isBlockedByMe ? Icons.block_rounded : Icons.lock_rounded;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1518) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.redAccent.withOpacity(isDark ? 0.36 : 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF7F1D1D),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF991B1B),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (isBlockedByMe) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: isLoadingBlock ? null : toggleBlock,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: const Text(
                      "Desbloquear contacto",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBlockedComposer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.do_not_disturb_on_rounded,
                  color: Colors.grey,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isBlockedByMe
                      ? "Desbloquea a este contacto para volver a escribirle."
                      : "No puedes enviar mensajes en este chat.",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = !isBlockedByMe && !isBlockedByOther;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF071A16) : const Color(0xFFF6F8F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF071A16) : const Color(0xFFF6F8F7),
        titleSpacing: 0,
        title: Row(
          children: [
            InkWell(
              onTap: openContactProfile,
              borderRadius: BorderRadius.circular(999),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: Colors.green.shade600,
                backgroundImage: contactImageProvider,
                child: contactImageProvider == null
                    ? Text(
                        contactInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: openContactProfile,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isBlockedByMe
                            ? "Contacto bloqueado"
                            : isBlockedByOther
                                ? "No disponible"
                                : "En linea",
                        style: TextStyle(
                          fontSize: 12,
                          color: isBlockedByMe || isBlockedByOther
                              ? Colors.redAccent
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == "refresh") {
                await loadMessages();
                return;
              }
              if (value == "clear") {
                setState(() => messages = []);
                return;
              }
              if (value == "block") {
                await toggleBlock();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: "refresh",
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.green),
                    SizedBox(width: 10),
                    Text("Actualizar chat"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: "clear",
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_rounded,
                        color: Colors.blueGrey),
                    SizedBox(width: 10),
                    Text("Limpiar vista"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "block",
                child: Row(
                  children: [
                    Icon(
                      isBlockedByMe
                          ? Icons.lock_open_rounded
                          : Icons.block_rounded,
                      color: isBlockedByMe ? Colors.green : Colors.redAccent,
                    ),
                    const SizedBox(width: 10),
                    Text(isBlockedByMe ? "Desbloquear" : "Bloquear contacto"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          buildBlockBanner(),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      "Aun no hay mensajes",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final isMe = msg["sender_id"] != widget.userId;

                      bool shouldShowDate(int index) {
                        if (index == messages.length - 1) return true;
                        final current = parseMessageDate(
                          messages[index]["timestamp"],
                        );
                        final next = parseMessageDate(
                          messages[index + 1]["timestamp"],
                        );
                        if (current == null || next == null) return false;
                        return current.day != next.day ||
                            current.month != next.month ||
                            current.year != next.year;
                      }

                      return Column(
                        children: [
                          if (shouldShowDate(i))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                formatTimestamp(
                                  parseMessageDate(messages[i]["timestamp"]),
                                ),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          buildMessageBubble(msg, isMe),
                        ],
                      );
                    },
                  ),
          ),
          if (isTyping && canSend)
            const Padding(
              padding: EdgeInsets.only(left: 18, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Escribiendo...",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          if (canSend)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  quickActionChip(
                    icon: Icons.waving_hand_rounded,
                    label: "Saludar",
                    onTap: () => sendQuickMessage("Hola, ¿como vas?"),
                  ),
                  const SizedBox(width: 8),
                  quickActionChip(
                    icon: Icons.schedule_rounded,
                    label: "Coordinar",
                    onTap: () => sendQuickMessage(
                      "¿Podemos coordinar esto para hoy?",
                    ),
                  ),
                  const SizedBox(width: 8),
                  quickActionChip(
                    icon: Icons.check_circle_outline_rounded,
                    label: "Confirmar",
                    onTap: () => sendQuickMessage("Confirmado, gracias."),
                  ),
                  const SizedBox(width: 8),
                  quickActionChip(
                    icon: Icons.help_outline_rounded,
                    label: "Pedir detalle",
                    onTap: () => sendQuickMessage(
                      "¿Me puedes compartir mas detalles?",
                    ),
                  ),
                ],
              ),
            ),
          if (canSend)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    PopupMenuButton<String>(
                      enabled: canSend,
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: canSend ? Colors.green : Colors.grey,
                      ),
                    onSelected: (value) {
                      final templates = {
                        "thanks": "Gracias, quedo atento.",
                        "later": "Te respondo con calma en un momento.",
                        "amount": "¿Me confirmas el valor exacto?",
                      };
                      controller.text = templates[value] ?? "";
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                      setState(() => isTyping = controller.text.isNotEmpty);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: "thanks",
                        child: Text("Plantilla: agradecimiento"),
                      ),
                      PopupMenuItem(
                        value: "later",
                        child: Text("Plantilla: responder luego"),
                      ),
                      PopupMenuItem(
                        value: "amount",
                        child: Text("Plantilla: confirmar valor"),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        enabled: canSend,
                        onChanged: (text) {
                          setState(() => isTyping = text.isNotEmpty);
                        },
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: canSend
                              ? "Escribe un mensaje..."
                              : "Chat bloqueado",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: canSend && !isLoadingBlock ? sendMessage : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        gradient: canSend
                            ? LinearGradient(
                                colors: [
                                  Colors.green.shade500,
                                  Colors.green.shade700,
                                ],
                              )
                            : null,
                        color: canSend ? null : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                    ),
                  ],
                ),
              ),
            )
          else
            buildBlockedComposer(),
        ],
      ),
    );
  }
}
