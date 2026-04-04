import 'package:flutter/material.dart';


/// Widget que muestra el carrusel de contenido educativo (Quick Wins)
class FinaraQuickWins extends StatelessWidget {
  const FinaraQuickWins({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Título de sección
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'QUICK WINS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// Carrusel horizontal
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: CarouselView(
            itemExtent: 300,
            shrinkExtent: 200,
            children: const [
              QuickWinCard(
                categoria: "INVESTING BASICS",
                titulo: "Mastering Bull Markets",
                tiempo: "5 min read",
              ),
              QuickWinCard(
                categoria: "AI ASSISTANT",
                titulo: "Optimizing Portfolios",
                tiempo: "3 min read",
              ),
              QuickWinCard(
                categoria: "FINANCE",
                titulo: "Risk Management",
                tiempo: "8 min read",
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta individual dentro del carrusel
class QuickWinCard extends StatelessWidget {
  final String categoria;
  final String titulo;
  final String tiempo;

  const QuickWinCard({
    super.key,
    required this.categoria,
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
          /// Categoría
          Text(
            categoria,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 8),

          /// Título principal
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

          /// Footer (tiempo + botón)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Tiempo estimado
              Row(
                children: [
                  const Icon(Icons.access_time,
                      color: Colors.white, size: 12),
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

              /// Botón de acción
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  "CONTINUE",
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