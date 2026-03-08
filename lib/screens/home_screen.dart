import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Finara"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),

            onPressed: () {
              auth.logout();

              Navigator.pushReplacementNamed(context, "/login");
            },
          ),
        ],
      ),

      body: FutureBuilder(
        future: context.read<AuthProvider>().getUserData(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;

          return Center(
            child: Text(
              "Bienvenido ${user["name"]}",
              style: const TextStyle(fontSize: 22),
            ),
          );
        },
      ),
    );
  }
}
