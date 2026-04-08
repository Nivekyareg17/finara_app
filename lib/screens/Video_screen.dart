import 'package:finara_app_v1/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:finara_app_v1/main.dart';
import '../widgets/custom_bottom_nav.dart';
import 'video_list_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  List categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void loadCategories() async {
    try {
      final data = await ApiService.getCategories();
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(4)),
              child: Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 18),
            ),
            SizedBox(width: 8),
            Text("Learn",
                style: TextStyle(
                    color: Color.fromARGB(255, 10, 109, 82),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return ListTile(
                  title: Text(category["title"]),
                  subtitle: Text(category["description"]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            VideoListScreen(categoryId: category["id"]),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: const CustomBottomNav(
        selectedIndex: 3,
      ),
    );
  }

  // --- WIDGETS CON INTERACCIÓN ---

  Widget _buildFeaturedCard({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient:
              LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF1B4332)]),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Color(0xFF40916C),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text("DESTACADO",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 8),
                  Text("Introducción a la inversión en\nCripto",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text("12:45 • Módulo 1",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Center(
                child: Icon(Icons.play_circle_fill,
                    size: 60, color: Colors.white.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList() {
    return Container(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSquareCard("Ciclos de Mercado 101", "8:20 • 75% visto",
              onTap: () => print("Click Ciclos")),
          _buildSquareCard("Patrones de Velas", "15:40 • 30% visto",
              onTap: () => print("Click Velas")),
        ],
      ),
    );
  }

  Widget _buildTechnicalGrid() {
    return Row(
      children: [
        Expanded(
            child: _buildSquareCard("Dominando indicadores RSI", "4:12",
                onTap: () => print("Click RSI"))),
        SizedBox(width: 12),
        Expanded(
            child: _buildSquareCard("Zonas de Soporte y Resistencia", "6:55",
                onTap: () => print("Click Soporte"))),
      ],
    );
  }

  Widget _buildSquareCard(String title, String subtitle,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 200,
        padding: EdgeInsets.all(4), // Espaciado para el ripple
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                  color: Color(0xFF95D5B2).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15)),
              child: Center(
                  child: Icon(Icons.play_circle_outline, color: Colors.white)),
            ),
            SizedBox(height: 8),
            Text(title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalList() {
    return Column(
      children: [
        _buildListTile(
            "La magia del interés compuesto", "Módulo 1 • 12 mins", true,
            onTap: () => print("Click Interés")),
        _buildListTile("Conceptos básicos de eficiencia fiscal",
            "Módulo 2 • 18 mins", false,
            onTap: () => print("Click Fiscal")),
      ],
    );
  }

  Widget _buildListTile(String title, String sub, bool completed,
      {required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: Color(0xFF52796F),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(sub,
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    SizedBox(height: 4),
                    completed
                        ? Text("VISTO ✓",
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold))
                        : Text("EMPEZAR AHORA →",
                            style: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 0.5)),
          if (title == "VIDEOS POPULARES")
            TextButton(
              onPressed: () => print("Ver todos"),
              child: Text("Ver todos",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
