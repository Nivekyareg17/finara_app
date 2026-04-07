import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/api_service.dart';
import 'video_player_screen.dart';
import '../widgets/custom_bottom_nav.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  List categories = [];
  Map<int, List> videosByCategory = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    try {
      final cats = await ApiService.getCategories();

      for (var cat in cats) {
        final vids = await ApiService.getVideos(cat["id"]);
        videosByCategory[cat["id"]] = vids;
      }

      setState(() {
        categories = cats;
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.play_circle_fill,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text("Videos",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 🔥 VIDEO DESTACADO
                if (categories.isNotEmpty)
                  _buildFeatured(videosByCategory[categories[0]["id"]]),

                // 🔥 LISTAS POR CATEGORÍA
                ...categories.map((category) {
                  final videos = videosByCategory[category["id"]] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          category["title"].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey[600],
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: videos.length,
                          itemBuilder: (context, index) {
                            final video = videos[index];

                            final videoId =
                                YoutubePlayer.convertUrlToId(video["url"]);
                            final thumbnail =
                                "https://img.youtube.com/vi/$videoId/0.jpg";

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VideoPlayerScreen(url: video["url"]),
                                  ),
                                );
                              },
                              child: Container(
                                width: 160,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: Image.network(
                                        thumbnail,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      video["title"],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
    );
  }

  // 🔥 VIDEO DESTACADO
  Widget _buildFeatured(List? videos) {
    if (videos == null || videos.isEmpty) return const SizedBox();

    final video = videos[0];
    final videoId = YoutubePlayer.convertUrlToId(video["url"]);
    final thumbnail = "https://img.youtube.com/vi/$videoId/0.jpg";

    return Padding(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(url: video["url"]),
            ),
          );
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                thumbnail,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // overlay oscuro
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            // texto
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("DESTACADO",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 250,
                    child: Text(
                      video["title"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // botón play
            const Positioned.fill(
              child: Center(
                child: Icon(Icons.play_circle_fill,
                    size: 70, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}