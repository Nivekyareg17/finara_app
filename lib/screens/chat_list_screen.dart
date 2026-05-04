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
  List users = [];

  Future<void> loadUsers() async {
    final auth = context.read<AuthProvider>();
    final data = await ApiService.getUsersPublic(auth.token!);

    setState(() {
      users = data;
    });
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, i) {
          final user = users[i];

          return ListTile(
            leading: CircleAvatar(
              child: Text(user["name"][0]),
            ),
            title: Text(user["name"]),
            subtitle: const Text("Toca para chatear"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    userId: user["id"],
                    userName: user["name"],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
