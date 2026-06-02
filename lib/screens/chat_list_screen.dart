import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import '../widgets/custom_bottom_nav.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  List users = [];
  List requests = [];
  bool isLoadingChats = true;
  bool isLoadingRequests = true;

  late TabController tabController;

  ImageProvider? imageProviderFrom(dynamic rawValue) {
    final rawUrl = rawValue?.toString().trim();
    if (rawUrl == null || rawUrl.isEmpty) return null;

    if (rawUrl.startsWith("data:")) {
      try {
        final commaIndex = rawUrl.indexOf(",");
        if (commaIndex == -1) return null;
        final imageData = rawUrl.substring(commaIndex + 1).split("?").first;
        return MemoryImage(base64Decode(imageData));
      } catch (_) {
        return null;
      }
    }

    if (!kIsWeb && rawUrl.startsWith("file:")) return null;
    if (rawUrl.startsWith("http")) return NetworkImage(rawUrl);
    return NetworkImage(
      "${ApiService.baseUrl}${rawUrl.startsWith("/") ? "" : "/"}$rawUrl",
    );
  }

  String initialFrom(dynamic name) {
    final value = name?.toString().trim();
    return value == null || value.isEmpty ? "U" : value[0].toUpperCase();
  }

  dynamic profileImageFrom(Map user) {
    return user["profile_image_url"] ??
        user["profileImageUrl"] ??
        user["avatar"] ??
        user["sender_profile_image_url"];
  }

  Widget chatAvatar({
    required double size,
    required dynamic name,
    dynamic imageUrl,
    bool showRing = false,
  }) {
    final imageProvider = imageProviderFrom(imageUrl);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.14),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initialFrom(name),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );

    final avatar = imageProvider == null
        ? fallback
        : ClipOval(
            child: Image(
              image: imageProvider,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
          );

    if (!showRing) return avatar;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0F8F5F), width: 2),
      ),
      child: avatar,
    );
  }

  String formatLastTime(dynamic raw) {
    final value = raw?.toString();
    if (value == null || value.isEmpty) return "";
    final parsed = DateTime.tryParse(value.replaceFirst(" ", "T"));
    if (parsed == null) {
      return value.length >= 16 ? value.substring(11, 16) : value;
    }
    final now = DateTime.now();
    if (parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day) {
      return "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
    }
    return "${parsed.day}/${parsed.month}";
  }

  Future<void> loadChats() async {
    try {
      final auth = context.read<AuthProvider>();
      final data = await ApiService.getChats(auth.token!);
      if (!mounted) return;
      setState(() {
        users = data;
        isLoadingChats = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoadingChats = false);
    }
  }

  Future<void> loadRequests() async {
    try {
      final auth = context.read<AuthProvider>();
      final data = await ApiService.getRequests(auth.token!);
      if (!mounted) return;
      setState(() {
        requests = data;
        isLoadingRequests = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoadingRequests = false);
    }
  }

Future<void> openSearchDialog() async {
    final controller = TextEditingController();
    Map<String, dynamic>? foundUser;
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              backgroundColor: theme.scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                "Buscar usuario",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Correo electrónico",
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: theme.brightness == Brightness.light 
                          ? Colors.grey.shade100 
                          : Colors.grey.shade900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSearching ? null : () async {
                        setDialogState(() => isSearching = true);
                        final auth = context.read<AuthProvider>();
                        final user = await ApiService.searchUserByEmail(
                          auth.token!,
                          controller.text,
                        );
                        setDialogState(() {
                          foundUser = user;
                          isSearching = false;
                        });
                      },
                      child: isSearching 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text("Buscar", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (foundUser != null || isSearching) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
                  if (foundUser != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 22,
                            child: chatAvatar(
                              size: 44,
                              name: foundUser!["name"],
                              imageUrl: profileImageFrom(foundUser!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  foundUser!["name"],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  foundUser!["email"],
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          final auth = context.read<AuthProvider>();
                          final result = await ApiService.sendMessageRequest(
                            auth.token!,
                            foundUser!["id"],
                          );

                          if (!mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result["message"]),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );

                          loadRequests();
                        },
                        child: const Text("Enviar solicitud", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    loadChats();
    loadRequests();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),

            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),

            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF071A16),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF071A16),
        title: Text(
          "Mensajes",
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.search_rounded, color: theme.primaryColor),
                onPressed: openSearchDialog,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
          tabs: [
            const Tab(text: "Chats"),
            Tab(
              text: requests.isEmpty
                  ? "Solicitudes"
                  : "Solicitudes (${requests.length})",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          //TAB CHATS
          isLoadingChats
              ? const Center(child: CircularProgressIndicator())
              : users.isEmpty
                  ? _buildEmptyState(
                      context,
                      Icons.chat_bubble_outline_rounded,
                      "No hay conversaciones",
                      "Busca un usuario mediante su correo electrónico para iniciar un chat.",
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                      itemCount: users.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final user = users[i];
                        final hasMessage = user["last_message"] != null;
                        final imageUrl = profileImageFrom(user);
                        final description =
                            user["description"]?.toString().trim();

                        return InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  userId: user["id"],
                                  userName: user["name"],
                                  userImageUrl: user["profile_image_url"] ??
                                      user["profileImageUrl"] ??
                                      user["avatar"],
                                  userDescription: user["description"],
                                ),
                              ),
                            );
                            loadChats();
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
                            child: Row(
                              children: [
                                chatAvatar(
                                  size: 58,
                                  name: user["name"],
                                  imageUrl: imageUrl,
                                  showRing: imageUrl != null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user["name"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user["last_message"] ?? "Sin mensajes aún",
                                        style: TextStyle(
                                          color: hasMessage
                                              ? (theme.brightness ==
                                                      Brightness.light
                                                  ? const Color(0xFF65676B)
                                                  : Colors.white60)
                                              : Colors.grey.shade400,
                                          fontSize: 14,
                                          fontStyle: hasMessage ? FontStyle.normal : FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (description != null &&
                                          description.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          description,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (user["last_time"] != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatLastTime(user["last_time"]),
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F8F5F),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

          //TAB SOLICITUDES
          isLoadingRequests
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
                  ? _buildEmptyState(
                      context,
                      Icons.people_outline_rounded,
                      "Todo al día",
                      "No tienes solicitudes de chat pendientes en este momento.",
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? Colors.grey.shade50
                                : Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.transparent,
                                radius: 22,
                                child: chatAvatar(
                                  size: 44,
                                  name: request["sender_name"],
                                  imageUrl: profileImageFrom(request),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request["sender_name"] ?? "Usuario",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      request["sender_email"] ?? "",
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                                    onPressed: () async {
                                      final auth = context.read<AuthProvider>();
                                      await ApiService.acceptRequest(auth.token!, request["id"]);
                                      loadChats();
                                      loadRequests();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.cancel_rounded, color: Colors.red.shade400, size: 28),
                                    onPressed: () async {
                                      final auth = context.read<AuthProvider>();
                                      await ApiService.rejectRequest(auth.token!, request["id"]);
                                      loadRequests();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(
        selectedIndex: 0,
      ),
    );
  }
}
