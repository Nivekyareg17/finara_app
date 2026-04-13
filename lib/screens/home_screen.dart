import 'package:finara_app_v1/screens/stock_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/QuickActionTile.dart';
import '../widgets/quick_wins.dart';
import '../widgets/statcard.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/translate_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF061A17) : const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              "assets/images/Logo_finara.png",
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_balance,
                  color: Color.fromRGBO(6, 78, 59, 1)),
            ),
            const SizedBox(width: 12),
            // El nombre de la marca suele quedarse igual, pero si quieres puedes usar TranslatedText
            const Text(
              "Finara",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 10, 109, 82),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // ESTADÍSTICAS (StatCard debe recibir Strings para traducir dentro o fuera)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: const [
                Expanded(
                  child: StatCard(
                    title: "COMPLETADO",
                    count: "24",
                    unit: "Lecciones",
                    icon: Icons.emoji_events_outlined,
                    accentColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: "CRÉDITOS IA",
                    count: "850",
                    unit: "Restantes",
                    icon: Icons.auto_awesome,
                    accentColor: Color(0xFF2ECC71),
                  ),
                ),
              ],
            ),
          ),

          const FinaraQuickWins(),

          const SizedBox(height: 25),

          // TÍTULO DE SECCIÓN
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: TranslatedText(
              'ACCIONES RÁPIDAS', // Cambiado de QUICK ACTIONS
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ACCESO AL CHAT IA
          QuickActionTile(
            title: "Pregunta a Finara AI", // Traducido base
            subtitle: "Asesoría experta 24/7", // Traducido base
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF1E8449),
            onTap: () => Navigator.pushReplacementNamed(context, "/daiko_ai"),
          ),

          // VISTA DE MERCADO
          QuickActionTile(
            title: "Mercado de Valores", // Traducido base
            subtitle: "Ver precios en vivo", // Traducido base
            icon: Icons.show_chart,
            iconColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StocksScreen(),
                ),
              );
            },
          ),

          // RUTA DE APRENDIZAJE
          QuickActionTile(
            title: "Ruta de Aprendizaje", // Traducido base
            subtitle: "3 módulos para completar hoy", // Traducido base
            icon: Icons.school_outlined,
            iconColor: Colors.purple,
            onTap: () => Navigator.pushReplacementNamed(context, "/video"),
          ),

          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
    );
  }
}