import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        // Pick up logotype and text "Finara"
        title: Row(
          children: [
            Image.asset("assets/images/Logo_finara.png",width: 30,height: 30,),
            const SizedBox(width: 12),
            const Text("Finara", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 6, 78, 59))),
          ],
        ),

        //Pick up notification icon and profile icon
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Color.fromARGB(255, 90, 90, 91),),
            onPressed: () {
              // For now, just print a message to the console
              debugPrint("Botón de notificaciones presionado");

              /* Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PantallaProxima())
      );
      */
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              //For now, just print a message to the console
              debugPrint("Button of profile pressed");
              /* Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PantallaProxima())
      );
      */
            },
          )
        ],
      ),
    );
  }
}

class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFF064E3B); // Forest Green del HTML

    return Scaffold(
      // Estilo Glass en el AppBar
      appBar: AppBar(
        backgroundColor: isDark
            ? Colors.black.withOpacity(0.8)
            : Colors.white.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Education",
          style: TextStyle(
            color: isDark ? Colors.green[400] : primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // 1. VIDEO DESTACADO (Featured)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildFeaturedVideo(primaryColor),
          ),

          const SizedBox(height: 30),

          // 2. VIDEOS POPULARES (Horizontal Scroll)
          _buildSectionHeader("Popular Videos"),
          const SizedBox(height: 15),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              children: [
                _buildHorizontalCard(
                    "Market Cycles 101", "8:20", 0.75, primaryColor),
                _buildHorizontalCard(
                    "Candlestick Patterns", "15:40", 0.30, primaryColor),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 3. ANALISIS TECNICO (Grid)
          _buildSectionHeader("Technical Analysis"),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                    child: _buildGridItem(
                        "Mastering RSI Indicators", "4:12", primaryColor)),
                const SizedBox(width: 15),
                Expanded(
                    child: _buildGridItem(
                        "Support & Resistance Zones", "6:55", primaryColor)),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 4. LISTA DE FINANZAS (Vertical List)
          _buildSectionHeader("Personal Finance 101"),
          const SizedBox(height: 15),
          _buildVerticalItem("Compound Interest Magic", "Module 1 • 12 mins",
              true, primaryColor),
          _buildVerticalItem("Tax Efficiency Basics", "Module 2 • 18 mins",
              false, primaryColor),

          const SizedBox(height: 100), // Espacio para el BottomNav
        ],
      ),

      // BARRA DE NAVEGACION (Estilo Glass)
      bottomNavigationBar: _buildBottomNav(primaryColor, isDark),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
        onPressed: () {}, // Aquí iría Daiko
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
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2)),
          const Text("See All",
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFeaturedVideo(Color primary) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage("https://picsum.photos/400/200"),
          fit: BoxFit.cover,
          opacity: 0.8,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, primary.withOpacity(0.9)],
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30)),
              child:
                  const Icon(Icons.play_arrow, color: Colors.white, size: 40),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: Colors.green,
                  child: const Text("FEATURED",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 5),
                const Text("Introduction to Crypto Investing",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(
      String title, String duration, double progress, Color primary) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
                color: primary, borderRadius: BorderRadius.circular(20)),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                const Center(
                    child: Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 30)),
                Container(
                    height: 4, width: 200 * progress, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1),
          Text("$duration • ${(progress * 100).toInt()}% watched",
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGridItem(String title, String duration, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
              color: primary, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.play_circle, color: Colors.white54, size: 30),
        ),
        const SizedBox(height: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 2),
      ],
    );
  }

  Widget _buildVerticalItem(
      String title, String sub, bool watched, Color primary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.play_arrow, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sub,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                if (watched)
                  const Text("WATCHED",
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav(Color primary, bool isDark) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: isDark
          ? Colors.black.withOpacity(0.8)
          : Colors.white.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, "Home", false),
          _navItem(Icons.smart_display, "Videos", true),
          const SizedBox(width: 40), // Espacio para el botón flotante
          _navItem(Icons.school, "Learn", false),
          _navItem(Icons.person, "Profile", false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? Colors.green : Colors.grey, size: 24),
        Text(label,
            style: TextStyle(
                color: active ? Colors.green : Colors.grey, fontSize: 10)),
      ],
    );
  }
}
