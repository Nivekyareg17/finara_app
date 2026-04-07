import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/api_service.dart';
import 'video_player_screen.dart';

class VideoListScreen extends StatefulWidget {
  final int categoryId;

  const VideoListScreen({super.key, required this.categoryId});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List videos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  void loadVideos() async {
    try {
      final data = await ApiService.getVideos(widget.categoryId);
      setState(() {
        videos = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
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
            const Text(
              "Videos",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];

                final videoId =
                    YoutubePlayer.convertUrlToId(video["url"]);
                final thumbnail =
                    "https://img.youtube.com/vi/$videoId/0.jpg";

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VideoPlayerScreen(url: video["url"]),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                thumbnail,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),

                            // botón play encima
                            Positioned.fill(
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Título
                        Text(
                          video["title"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Texto secundario
                        const Text(
                          "Video educativo",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}