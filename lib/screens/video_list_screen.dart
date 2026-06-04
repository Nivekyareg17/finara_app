import 'package:finara_app_v1/screens/video_webView_Screen.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/translate_widget.dart';

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

      if (uri.queryParameters['v'] != null) {
        return uri.queryParameters['v']!;
      }

      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      }

      if (uri.pathSegments.contains('embed')) {
        return uri.pathSegments.last;
      }

      return '';
    } catch (e) {
      print("Error parsing URL: $e");
      return '';
    }
  }

  bool isValidYoutubeUrl(String url) {
    return url.contains("youtube.com") || url.contains("youtu.be");
  }

  String thumbnailFor(String videoId) {
    return "https://img.youtube.com/vi/$videoId/hqdefault.jpg";
  }

  void loadVideos() async {
    try {
      final data = await ApiService.getVideos(widget.categoryId);

      setState(() {
        videos = data.where((video) {
          return isValidYoutubeUrl(video["url"]?.toString() ?? "");
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void openVideo(Map video) {
    final videoId = getVideoId(video["url"]?.toString() ?? "");

    if (videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText("Video no valido")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoWebViewScreen(videoId: videoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8F7),
        title: const TranslatedText("Videos"),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 10, 109, 82),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : videos.isEmpty
              ? Center(
                  child: TranslatedText(
                    "No hay videos disponibles",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: videos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    final videoId = getVideoId(video["url"]?.toString() ?? "");
                    final thumbnail = thumbnailFor(videoId);
                    final title = video["title"]?.toString() ?? "Video";

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => openVideo(video),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color.fromARGB(255, 32, 32, 32)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      thumbnail,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFF0A6D52),
                                        child: const Icon(
                                          Icons.play_circle_fill_rounded,
                                          color: Colors.white,
                                          size: 58,
                                        ),
                                      ),
                                    ),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.05),
                                            Colors.black.withOpacity(0.72),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 14,
                                      top: 14,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00C853),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.ondemand_video_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 6),
                                            TranslatedText(
                                              "Video",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.92),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Color(0xFF0A6D52),
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TranslatedText(
                                    title,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_outlined,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey.shade600,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Ver ahora",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Color(0xFF00C853),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
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
