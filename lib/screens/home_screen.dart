import 'package:finara_app_v1/features/ai/model/chat_message.dart';
import 'package:finara_app_v1/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:finara_app_v1/features/ai/view/ai_chat_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
 
int currentIndex = 0;

final List<Widget> screens = [
  HomeScreen(),
  AIChatPage(), // tu contenido actual
  ProfileScreen(),
];
 @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF064E3B); // Forest Green de Finara
     
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF061A17) : const Color(0xFFF5F3F3),
      
      // 1. APPBAR UNIFICADA
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
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
            const Text("Finara",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          ],
        ),
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

      // 2. CUERPO CON SCROLL
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // SECCIÓN DE ESTADÍSTICAS (NUEVO)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
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

          // SECCIÓN DE QUICK WINS (CARRUSEL)
          const FinaraQuickWins(),

          const SizedBox(height: 25),

          // SECCIÓN DE ACCIONES RÁPIDAS (NUEVO)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'QUICK ACTIONS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 16),
          QuickActionTile(
            title: "Ask finara AI",
            subtitle: "Expert advisory 24/7",
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF1E8449),
            onTap: () => Navigator.pushNamed(context, "/daiko_ai"),
          ),
          QuickActionTile(
            title: "Market Overview",
            subtitle: "Global trends and economic insights",
            icon: Icons.bar_chart_rounded,
            iconColor: Colors.blue,
            onTap: () {},
          ),
          QuickActionTile(
            title: "Learning Path",
            subtitle: "3 modules to complete today",
            icon: Icons.school_outlined,
            iconColor: Colors.purple,
            onTap: () {},
          ),
          
          const SizedBox(height: 80), // Espacio para que el FAB no tape el contenido
        ],
      ),

      // 3. NAVEGACIÓN
     bottomNavigationBar: _buildBottomNav(primaryColor, isDark, context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
        onPressed: () => Navigator.pushNamed(context, "/daiko_ai"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav(Color primary, bool isDark, BuildContext context) {
  return BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 8,
    color: isDark ? Colors.black : Colors.white,
    child: SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [

          // 🏠 HOME
          IconButton(
            icon: const Icon(Icons.home, color: Colors.green),
            onPressed: () {
               Navigator.pushReplacementNamed(context, "/home");
              // ya estás en home
            },
          ),

          // 🎥 VIDEO / AI
          const Icon(Icons.smart_display, color: Colors.grey),

        const SizedBox(width: 40),

          const SizedBox(width: 40),

          // 📚 SCHOOL
          const Icon(Icons.school, color: Colors.grey),


          // 👤 PERFIL
         IconButton(
          icon: const Icon(Icons.person, color: Colors.grey),
          onPressed: () {
            Navigator.pushReplacementNamed(context, "/profile");
          },
          ),
        ],
      ),
    ),
  );
}
}

// --- WIDGETS DE APOYO AGREGADOS ---

class StatCard extends StatelessWidget {
  final String title, count, unit;
  final IconData icon;
  final Color accentColor;

  const StatCard({super.key, required this.title, required this.count, required this.unit, required this.icon, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const QuickActionTile({super.key, required this.title, required this.subtitle, required this.icon, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CLASE DEL CARRUSEL (Mantenida) ---
class FinaraQuickWins extends StatelessWidget {
  const FinaraQuickWins({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'QUICK WINS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: CarouselView(
            itemExtent: 300,
            shrinkExtent: 200,
            children: [
              _buildQuickCard("INVESTING BASICS", "Mastering Bull Markets", "5 min read"),
              _buildQuickCard("AI ASSISTANT", "Optimizing Portfolios", "3 min read"),
              _buildQuickCard("FINANCE", "Risk Management", "8 min read"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCard(String categoria, String titulo, String tiempo) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF064131),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(categoria, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(height: 8),
          Text(titulo, 
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(tiempo, style: const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: const Text("CONTINUE", style: TextStyle(color: Color(0xFF064131), fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ],
      ),
    );
  }
}