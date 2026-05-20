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
      appBar: AppBar(title: const Text("Chats"),titleTextStyle: TextStyle(fontSize: 25,color: const Color.fromARGB(221, 16, 75, 8),),),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: users.length,
        itemBuilder: (context, i) {
          final user = users[i];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 10),

              //AVATAR
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.green.shade600,
                child: Text(
                  user["name"][0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),

              //NOMBRE
              title: Text(
                user["name"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color.fromARGB(221, 27, 136, 13),
                ),
              ),

              //SUBTEXTO
              subtitle: const Text(
                "Toca para chatear",
                style: TextStyle(color: Colors.grey),
              ),

              //ICONO DERECHA
              trailing:
                  const Icon(Icons.chat_bubble_outline, color: Colors.green),

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
            ),
          );
        },
      ),
    );
  }
}
