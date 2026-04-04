import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/statcard.dart';
import '../widgets/QuickActionTile.dart';
import '../widgets/quick_wins.dart';

//Pantalla principal de la aplicación.
//Muestra estadísticas, accesos rápidos y contenido educativo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Detecta si el tema actual es oscuro
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Color principal de la app
    const Color primaryColor = Color(0xFF064E3B);

    return Scaffold(
      // Fondo dinámico según tema
      backgroundColor: isDark ? const Color(0xFF061A17) : const Color(0xFFF5F3F3),

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
            onPressed: () => debugPrint("Notificaciones"),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.grey),
            onPressed: () => debugPrint("Perfil"),
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

          const SizedBox(height: 25),

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
            onTap: () =>
                Navigator.pushReplacementNamed(context, "/daiko_ai"),
          ),

          //Vista de mercado
          QuickActionTile(
            title: "Market Overview",
            subtitle: "Global trends and insights",
            icon: Icons.bar_chart_rounded,
            iconColor: Colors.blue,
            onTap: () {},
          ),

          // Ruta de aprendizaje
          QuickActionTile(
            title: "Learning Path",
            subtitle: "3 modules to complete today",
            icon: Icons.school_outlined,
            iconColor: Colors.purple,
            onTap: () {},
          ),

          const SizedBox(height: 80),
        ],
      ),

      //NAVBAR GLOBAL 
      //Se usa el widget bar
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),

      // Posición del FAB integrada con el notch
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}