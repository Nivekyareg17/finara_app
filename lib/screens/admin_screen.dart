import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List users = [];

  Future<void> loadUsers() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token!;

    print("Cargando users...");

    final response = await ApiService.getUsers(token);
    print("USERS: $response");
    setState(() => users = response);
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final token = auth.token!;

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, i) {
          final user = users[i];

          return ListTile(
            title: Text(user["name"]),
            subtitle: Text("${user["email"]} - ${user["role"]}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // eliminar
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await ApiService.deleteUser(token, user["id"]);
                    loadUsers();
                  },
                ),

                // SI NO es admin => mostrar botón hacer admin
                if (user["role"] != "admin")
                  IconButton(
                    icon: const Icon(Icons.security),
                    onPressed: () async {
                      await ApiService.makeAdmin(token, user["id"]);
                      loadUsers();
                    },
                  ),

                // SI es admin => mostrar botón quitar admin
                if (user["role"] == "admin")
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () async {
                      await ApiService.removeAdmin(token, user["id"]);
                      loadUsers();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
