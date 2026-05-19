import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final searchController = TextEditingController();
  List users = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    final data = await ApiService.getUsersPublic(token);
    if (!mounted) return;

    setState(() {
      users = data;
      isLoading = false;
    });
  }

  Future<void> openSearchDialog() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null || token.isEmpty) return;

    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        Map<String, dynamic>? foundUser;
        bool searching = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Buscar por correo"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "correo@ejemplo.com",
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      setModalState(() {
                        searching = true;
                      });

                      final result = await ApiService.searchUserByEmail(
                        token,
                        controller.text.trim(),
                      );

                      setModalState(() {
                        foundUser = result;
                        searching = false;
                      });
                    },
                    child: searching
                        ? const CircularProgressIndicator()
                        : const Text("Buscar"),
                  ),
                  const SizedBox(height: 16),
                  if (foundUser != null)
                    Column(
                      children: [
                        Text(foundUser!["name"]),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final success = await ApiService.sendMessageRequest(
                              token,
                              foundUser!["id"],
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? "Solicitud enviada"
                                      : "No se pudo enviar",
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Enviar solicitud",
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredUsers = users.where((user) {
      final data = Map<String, dynamic>.from(user);
      final name = (data["name"] ?? "").toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase().trim());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: openSearchDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor:
                              const Color(0xFF087F5B).withOpacity(0.12),
                          child: const Icon(
                            Icons.forum_outlined,
                            color: Color(0xFF087F5B),
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "No hay chats disponibles",
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Inicia sesion de nuevo si tu cuenta ya expiro.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: "Buscar usuarios por nombre",
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: "Limpiar busqueda",
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() => searchQuery = "");
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor:
                              isDark ? const Color(0xFF1F2937) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF087F5B),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 34,
                                      backgroundColor: const Color(0xFF087F5B)
                                          .withOpacity(0.12),
                                      child: const Icon(
                                        Icons.person_search_rounded,
                                        color: Color(0xFF087F5B),
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      "No se encontraron usuarios",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: filteredUsers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final user = Map<String, dynamic>.from(
                                    filteredUsers[index]);
                                final name =
                                    (user["name"] ?? "Usuario").toString();
                                final initial = name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : "?";

                                return Material(
                                  color: isDark
                                      ? const Color(0xFF1F2937)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  elevation: isDark ? 0 : 1,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            userId: user["id"],
                                            userName: name,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor:
                                                const Color(0xFF087F5B),
                                            child: Text(
                                              initial,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  "Toca para chatear",
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Color(0xFF087F5B),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
