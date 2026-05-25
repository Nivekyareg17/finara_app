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

  late TabController tabController;

  Future<void> loadChats() async {
    final auth = context.read<AuthProvider>();

    final data = await ApiService.getChats(
      auth.token!,
    );

    if (!mounted) return;

    setState(() {
      users = data;
    });
  }

  Future<void> loadRequests() async {
    final auth = context.read<AuthProvider>();

    final data = await ApiService.getRequests(
      auth.token!,
    );

    setState(() {
      requests = data;
    });
  }

  Future<void> openSearchDialog() async {
    final controller = TextEditingController();

    Map<String, dynamic>? foundUser;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Buscar usuario",
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Correo electrónico",
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final auth = context.read<AuthProvider>();

                      final user = await ApiService.searchUserByEmail(
                        auth.token!,
                        controller.text,
                      );

                      setDialogState(() {
                        foundUser = user;
                      });
                    },
                    child: const Text(
                      "Buscar",
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  if (foundUser != null)
                    Column(
                      children: [
                        Text(
                          foundUser!["name"],
                        ),
                        Text(
                          foundUser!["email"],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final auth = context.read<AuthProvider>();

                            final result = await ApiService.sendMessageRequest(
                              auth.token!,
                              foundUser!["id"],
                            );

                            if (!mounted) return;

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result["message"],
                                ),
                              ),
                            );

                            loadRequests();
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

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chats",
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
            ),
            onPressed: openSearchDialog,
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: [
            const Tab(
              text: "Chats",
            ),
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
          // TAB CHATS
          ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.green.shade600,
                    child: Text(
                      user["name"][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    user["name"],
                  ),
                  subtitle: Text(
                    user["last_message"] ?? "Sin mensajes",
                  ),
                  trailing: Text(
                    user["last_time"] != null
                        ? user["last_time"].toString().substring(11, 16)
                        : "",
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          userId: user["id"],
                          userName: user["name"],
                        ),
                      ),
                    );

                    loadChats();
                  },
                ),
              );
            },
          ),

          // TAB SOLICITUDES
          ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];

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

                        await ApiService.acceptRequest(
                          auth.token!,
                          request["id"],
                        );

                        loadChats();
                        loadRequests();
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final auth = context.read<AuthProvider>();

                        await ApiService.rejectRequest(
                          auth.token!,
                          request["id"],
                        );

                        loadRequests();
                      },
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
