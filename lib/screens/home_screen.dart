import 'package:flutter/material.dart';
import '../widgets/QuickActionTile.dart';
import '../widgets/quick_wins.dart';
import '../widgets/statcard.dart';
import '../widgets/custom_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Detecta si el tema actual es oscuro
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Color principal de la app
    const Color primaryColor = Color(0xFF064E3B);

    return Scaffold(
      // Fondo dinámico según tema
      backgroundColor:
          isDark ? const Color(0xFF061A17) : const Color(0xFFF5F3F3),

      // APP BAR
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,

        //Logo + nombre
        title: Row(
          children: [
            Image.asset(
              "assets/images/Logo_finara.png",
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.account_balance, color: primaryColor),
            ),
            const SizedBox(width: 12),
            const Text(
              "Finara",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),

        //Acciones del lado derecho
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.grey),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.grey),
            onPressed: () {
              Navigator.pushReplacementNamed(context, "/profile");
            },
          )
        ],
      ),

      //BODY
      //Contenido principal con scroll
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          //ESTADÍSTICAS
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

          //CARRUSEL
          const FinaraQuickWins(),

          const SizedBox(height: 25),

          //ACCIONES RÁPIDAS
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          //Acceso al chat IA
          QuickActionTile(
            title: "Ask Finara AI",
            subtitle: "Expert advisory 24/7",
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF1E8449),
            onTap: () => Navigator.pushReplacementNamed(context, "/daiko_ai"),
          ),

          //Vista de mercado
          QuickActionTile(
            title: "Market Overview",
            subtitle: "Global trends and insights",
            icon: Icons.bar_chart_rounded,
            iconColor: Colors.blue,
            onTap: () => Navigator.pushReplacementNamed(context, "/news"),
          ),

          // Ruta de aprendizaje
          QuickActionTile(
            title: "Learning Path",
            subtitle: "3 modules to complete today",
            icon: Icons.school_outlined,
            iconColor: Colors.purple,
            onTap: () => Navigator.pushReplacementNamed(context, "/video"),
          ),

          const SizedBox(height: 80),
        ],
      ),

      //NAVBAR GLOBAL
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),

    );
  }

  void _showNotifications(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notificaciones",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.trending_up, color: Colors.green),
                    title: Text("BTC subió 5%"),
                    subtitle: Text("Hace 2 minutos"),
                  ),
                  ListTile(
                    leading: Icon(Icons.warning, color: Colors.orange),
                    title: Text("Alta volatilidad detectada"),
                    subtitle: Text("Hace 10 minutos"),
                  ),
                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.blue),
                    title: Text("Transacción completada"),
                    subtitle: Text("Hace 1 hora"),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
  }
}
