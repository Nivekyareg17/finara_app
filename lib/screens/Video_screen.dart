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
            Text("Videos",
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

}
