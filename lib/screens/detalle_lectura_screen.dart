import 'package:flutter/material.dart';
import '../widgets/translate_widget.dart';
class DetalleLecturaScreen extends StatelessWidget {
  final Map lectura;

  const DetalleLecturaScreen({super.key, required this.lectura});

  @override
  Widget build(BuildContext context) {
    final parrafos = lectura['contenido'].split('\n');

    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(lectura['titulo']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TranslatedText(
              lectura['titulo'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Tiempo de lectura: ${lectura['tiempo_lectura']}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            ...parrafos.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TranslatedText(
                p,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            )),
          ],
        ),
      ),
    );
  }
}