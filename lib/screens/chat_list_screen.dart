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

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final searchController = TextEditingController();
  List users = [];
  List requests = [];
  late TabController tabController;
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 2,
      vsync: this,
    );

    loadChats();
    loadRequests();
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadChats() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    final data = await ApiService.getChats(token);
    if (!mounted) return;

    setState(() {
      users = data;
      isLoading = false;
    });
  }

  Future<void> loadRequests() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null || token.isEmpty) return;

    final data = await ApiService.getRequests(token);

    if (!mounted) return;

    setState(() {
      requests = data;
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
                            final result = await ApiService.sendMessageRequest(
                              token,
                              foundUser!["id"],
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result["message"],
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
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: "Chats"),
            Tab(text: "Solicitudes"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: openSearchDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // TAB CHATS CAUSA pe
          users.isEmpty
              ? const Center(
                  child: Text(
                    "No tienes chats",
                  ),
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = Map<String, dynamic>.from(
                      users[index],
                    );

                    final name = (user["name"] ?? "Usuario").toString();

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          name[0].toUpperCase(),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        user["email"] ?? "",
                      ),
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
                    );
                  },
                ),

          // TAB SOLICITUDES chamo
          requests.isEmpty
              ? const Center(
                  child: Text(
                    "No tienes solicitudes",
                  ),
                )
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = Map<String, dynamic>.from(
                      requests[index],
                    );

                    return ListTile(
                      title: Text(
                        request["sender_name"] ?? "Usuario",
                      ),
                      subtitle: Text(
                        request["sender_email"] ?? "",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                            onPressed: () async {
                              final auth = context.read<AuthProvider>();

                              final success = await ApiService.acceptRequest(
                                auth.token!,
                                request["id"],
                              );

                              if (success) {
                                loadRequests();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final auth = context.read<AuthProvider>();

                              final success = await ApiService.rejectRequest(
                                auth.token!,
                                request["id"],
                              );

                              if (success) {
                                loadRequests();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
