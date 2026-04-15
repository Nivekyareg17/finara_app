import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/detalle_lectura_screen.dart';
import '../screens/lecturas_screen.dart';
import 'translate_widget.dart'; // 1. Importamos el traductor

class FinaraQuickWins extends StatelessWidget {
  const FinaraQuickWins({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return FutureBuilder(
      future: ApiService.obtenerLecturas(),// Asegúrate de que este método exista en tu ApiService
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            // 2. Traducción para el mensaje de error
            child: TranslatedText("Error al cargar lecturas"),
          );
        }

        final lecturas = snapshot.data;

        if (lecturas == null || lecturas.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            // 3. Traducción para estado vacío
            child: TranslatedText("No hay lecturas"),
          );
        }

        final primeras = lecturas.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 4. Traducción del título de sección
                  const TranslatedText(
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
                    // 5. Traducción del botón "Ver más"
                    child: const TranslatedText("Ver más"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

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
                          // 6. Pasamos los datos dinámicos
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
          // 7. Traducción del Título de la lectura (Dinámico)
          TranslatedText(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  // 8. Traducción del tiempo (ej: "5 min" -> "5 mins")
                  TranslatedText(
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
                // 9. Traducción de la etiqueta del botón de la tarjeta
                child: const TranslatedText(
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