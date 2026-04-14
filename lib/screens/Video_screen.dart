import 'package:finara_app_v1/services/api_service.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'video_list_screen.dart';
import '../widgets/translate_widget.dart';
import '../widgets/app_drawer.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0B1220) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.play_circle_fill,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const TranslatedText(
              "Learn",
              style: TextStyle(
                color: Color(0xFF0A6D52),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoListScreen(
                            categoryId: category["id"],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: Row(
                        children: [
                          // Icono categoría
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Color(0xFF00C853),
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Texto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TranslatedText(
                                  category["title"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TranslatedText(
                                  category["description"],
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Flecha
                          Icon(Icons.arrow_forward_ios_rounded,color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
    );
  }
}
