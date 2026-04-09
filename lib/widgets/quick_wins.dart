import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/detalle_lectura_screen.dart';
import '../screens/lecturas_screen.dart';

class FinaraQuickWins extends StatelessWidget {
  const FinaraQuickWins({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return FutureBuilder(
      future: apiService.obtenerLecturas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Error al cargar lecturas"),
          );
        }

        final lecturas = snapshot.data;

        if (lecturas == null || lecturas.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No hay lecturas"),
          );
        }

        final primeras = lecturas.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TÍTULO + BOTÓN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LECTURAS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LecturasScreen(),
                        ),
                      );
                    },
                    child: const Text("Ver más"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// CARRUSEL DINÁMICO
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: primeras.map((lectura) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetalleLecturaScreen(lectura: lectura),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 280,
                        child: LecturaCard(
                          titulo: lectura['titulo'],
                          tiempo: lectura['tiempo_lectura'],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// TARJETA (igual estilo que la tuya)
class LecturaCard extends StatelessWidget {
  final String titulo;
  final String tiempo;

  const LecturaCard({
    super.key,
    required this.titulo,
    required this.tiempo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF064131),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Título
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          /// Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    tiempo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  "LEER",
                  style: TextStyle(
                    color: Color(0xFF064131),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
