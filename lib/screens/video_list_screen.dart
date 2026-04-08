import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'video_player_screen.dart';
import '../widgets/custom_bottom_nav.dart';

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

  String getVideoId(String url) {
    try {
      final uri = Uri.parse(url);

      // Caso 1: youtube.com/watch?v=ID
      if (uri.queryParameters['v'] != null) {
        return uri.queryParameters['v']!;
      }

      // Caso 2: youtu.be/ID
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      }

      // Caso 3: embed
      if (uri.pathSegments.contains('embed')) {
        return uri.pathSegments.last;
      }

      return '';
    } catch (e) {
      print("Error parsing URL: $e");
      return '';
    }
  }

  //verifica si es embed
  bool isValidYoutubeUrl(String url) {
    return url.contains("youtube.com") || url.contains("youtu.be");
  }

  void loadVideos() async {
    try {
      final data = await ApiService.getVideos(widget.categoryId);

      setState(() {
        videos = data.where((video) {
          return isValidYoutubeUrl(video["url"]);
        }).toList();

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
        title: const Text("Videos"),
        
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];

                //obtener thumbnail
                final videoId = getVideoId(video["url"]);
                final thumbnail = "https://img.youtube.com/vi/$videoId/0.jpg";

                return Card(
                  margin: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (video["url"] == null || video["url"].isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Video no disponible")),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(url: video["url"]),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Imagen del video
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            thumbnail,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),

                        //Título
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            video["title"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
           bottomNavigationBar: const CustomBottomNav(
        selectedIndex: 3,
      ), 
    );
    
  }
}
