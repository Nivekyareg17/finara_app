import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

      // 2. CUERPO CON SCROLL (ListView)
      body: ListView(
        children: [
          // SECCIÓN DE QUICK WINS (CARRUSEL)
          const FinaraQuickWins(),

          const SizedBox(height: 20),

          // SECCIÓN DE VIDEOS POPULARES
          _buildSectionHeader("Popular Videos"),
          const SizedBox(height: 15),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              children: [
                _buildHorizontalCard("Market Cycles 101", "8:20", 0.75, primaryColor),
                _buildHorizontalCard("Candlestick Patterns", "15:40", 0.30, primaryColor),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // SECCIÓN DE ANÁLISIS TÉCNICO
          _buildSectionHeader("Technical Analysis"),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _buildGridItem("Mastering RSI", "4:12", primaryColor)),
                const SizedBox(width: 15),
                Expanded(child: _buildGridItem("Support Zones", "6:55", primaryColor)),
              ],
            ),
          ),
          
          const SizedBox(height: 100), // Espacio extra abajo
        ],
      ),

      // 3. NAVEGACIÓN
      bottomNavigationBar: _buildBottomNav(primaryColor, isDark),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
        onPressed: () => Navigator.pushNamed(context, "/daiko_ai"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // --- WIDGETS DE APOYO ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const Text("See All", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(String title, String duration, double progress, Color primary) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(20)),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 30)),
                Container(height: 4, width: 200 * progress, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
          Text("$duration • ${(progress * 100).toInt()}% watched", style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGridItem(String title, String duration, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.play_circle, color: Colors.white54, size: 30),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2),
      ],
    );
  }

  Widget _buildBottomNav(Color primary, bool isDark) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: isDark ? Colors.black : Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(Icons.home, color: Colors.green),
            const Icon(Icons.smart_display, color: Colors.grey),
            const SizedBox(width: 40),
            const Icon(Icons.school, color: Colors.grey),
            const Icon(Icons.person, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// --- CLASE DEL CARRUSEL (Corregida) ---

class FinaraQuickWins extends StatelessWidget {
  const FinaraQuickWins({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'QUICK WINS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: CarouselView(
            itemExtent: 330,
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
          Text(categoria, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(titulo, 
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(tiempo, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF064131),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("CONTINUE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}