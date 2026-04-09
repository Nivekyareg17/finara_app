import 'package:finara_app_v1/screens/detalle_lectura_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LecturasScreen extends StatelessWidget {
  LecturasScreen({super.key});

  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lecturas"),
      ),
      body: FutureBuilder(
        future: apiService.obtenerLecturas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar lecturas"));
          }

          final lecturas = snapshot.data;

          if (lecturas == null || lecturas.isEmpty) {
            return const Center(child: Text("No hay lecturas"));
          }

          return ListView.builder(
            itemCount: lecturas.length,
            itemBuilder: (context, index) {
              final lectura = lecturas[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  title: Text(lectura['titulo']),
                  subtitle: Text(lectura['tiempo_lectura']),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleLecturaScreen(lectura: lectura),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
