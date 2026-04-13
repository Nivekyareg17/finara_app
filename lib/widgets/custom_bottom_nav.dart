import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/languaje_provider.dart'; // Importante para escuchar el idioma

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNav({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF10B981);
    
    // Escuchamos el provider para que la barra sepa cuándo traducir
    final langProv = context.watch<LanguageProvider>();

    return FutureBuilder(
      // Creamos un Future que espere la traducción de todas las etiquetas
      future: Future.wait([
        langProv.translate("INICIO"),
        langProv.translate("NOTICIAS"),
        langProv.translate("DAIKO"),
        langProv.translate("VIDEOS"),
        langProv.translate("PERFIL"),
      ]),
      builder: (context, AsyncSnapshot<List<String>> snapshot) {
        // Mientras traduce, usamos nombres por defecto
        final labels = snapshot.data ?? ["INICIO", "NOTICIAS", "DAIKO", "VIDEOS", "PERFIL"];

        return BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            if (index == selectedIndex) return;

            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, "/home");
                break;
              case 1:
                Navigator.pushReplacementNamed(context, "/news");
                break;
              case 2:
                Navigator.pushReplacementNamed(context, "/daiko_ai");
                break;
              case 3:
                Navigator.pushReplacementNamed(context, "/video");
                break;
              case 4:
                Navigator.pushReplacementNamed(context, "/profile");
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle:
              const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
              const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined), label: labels[0]),
            BottomNavigationBarItem(
                icon: const Icon(Icons.analytics_outlined), label: labels[1]),
            BottomNavigationBarItem(
                icon: const Icon(Icons.auto_awesome), label: labels[2]),
            BottomNavigationBarItem(
                icon: const Icon(Icons.account_balance_wallet_outlined), label: labels[3]),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline), label: labels[4]),
          ],
        );
      },
    );
  }
}