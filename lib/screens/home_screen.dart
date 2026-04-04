import 'package:finara_app_v1/screens/Video_screen.dart';
import 'package:finara_app_v1/screens/news_card.screen.dart';
import 'package:flutter/material.dart';
import 'package:finara_app_v1/features/ai/view/ai_chat_page.dart';
import 'package:finara_app_v1/screens/profile_screen.dart';
import 'package:finara_app_v1/screens/Video_screen.dart';
import 'package:finara_app_v1/screens/news_card.screen.dart';

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
    const Color primaryColor = Color(0xFF064E3B);

    return Scaffold(
      
      backgroundColor: isDark ? const Color(0xFF061A17) : const Color(0xFFF5F3F3),

      // 🔻 APPBAR
       

      // 🔻 BODY DINÁMICO
      body: _getSelectedScreen(),

      // 🔻 BOTÓN CENTRAL
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
        onPressed: () {
          setState(() => currentIndex = 2);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔻 BOTTOM NAV
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [

              IconButton(
                icon: Icon(Icons.home,
                    color: currentIndex == 0 ? Colors.green : Colors.grey),
                onPressed: () {
                  setState(() => currentIndex = 0);
                },
              ),

              IconButton(
                icon: Icon(Icons.smart_display,
                    color: currentIndex == 1 ? Colors.green : Colors.grey),
                onPressed: () {
                  setState(() => currentIndex = 1);
                },
              ),

              const SizedBox(width: 40),

              IconButton(
                icon: Icon(Icons.school,
                    color: currentIndex == 3 ? Colors.green : Colors.grey),
                onPressed: () {
                  setState(() => currentIndex = 3);
                },
              ),

              IconButton(
                icon: Icon(Icons.person,
                    color: currentIndex == 4 ? Colors.green : Colors.grey),
                onPressed: () {
                  setState(() => currentIndex = 4);
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  // 🔥 CONTROLADOR DE PANTALLAS
 Widget _getSelectedScreen() {
  switch (currentIndex) {
    case 0:
      return _homeContent();
    case 1:
      return const VideoScreen();
    case 2:
      return const AIChatPage(); 
    case 3:
      return const NewsScreen(); 
    case 4:
      return const ProfileScreen(); 
    default:
      return _homeContent();
  }
}

  // 🔥 TU HOME REAL (AQUÍ VA TODO TU CONTENIDO)
  Widget _homeContent() {
    return ListView(
  padding: const EdgeInsets.symmetric(vertical: 20),
  children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: "CRÉDITOS IA",
              count: "850",
              unit: "Restantes",
              icon: Icons.auto_awesome,
              accentColor: Colors.green,
            ),
          ),
        ],
      ),
    ),

    const SizedBox(height: 25),
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'RECOMMENDED FOR YOU',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    ),

    const SizedBox(height: 25),

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

    QuickActionTile(
      title: "Ask finara AI",
      subtitle: "Expert advisory 24/7",
      icon: Icons.chat_bubble_outline_rounded,
      iconColor: Colors.green,
      onTap: () {},
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

    const SizedBox(height: 80),
  ],
);
  }
}

extension on _HomeScreenState {
  Widget StatCard({required String title, required String count, required String unit, required IconData icon, required Color accentColor, }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text("$count $unit", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

class FinaraQuickWins extends StatelessWidget {
  const FinaraQuickWins({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Quick Wins aquí"),
    );
  }
}
class QuickActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
// 🔻 CARD SIMPLE (para que no te falle nada)
class _Card extends StatelessWidget {
  final String title;
  final String value;

  const _Card(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}