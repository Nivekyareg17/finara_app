import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'video_webview_screen.dart';
import '../widgets/custom_bottom_nav.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool hasError = false;
  late String videoId;

  @override
  void initState() {
    super.initState();

    videoId = getYoutubeId(widget.videoUrl);

    print("URL ORIGINAL: ${widget.videoUrl}");
    print("VIDEO ID: $videoId");

    if (videoId.isEmpty) {
      hasError = true;
    } else {
      _controller = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );

      _controller.loadVideoById(videoId: videoId);

      // Detectar error
      _controller.listen((event) {
        if (event.playerState == PlayerState.unknown) {
          setState(() {
            hasError = true;
          });
        }
      });
    }
  }

  String getYoutubeId(String url) {
    final uri = Uri.parse(url);

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    }

    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v']!;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reproductor"),
        titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 10, 109, 82),
            fontWeight: FontWeight.bold,
            fontSize: 18),
      ),
      body: Center(
        child: hasError
            ? _errorUI(context)
            : YoutubePlayer(controller: _controller),
      ),
      bottomNavigationBar: const CustomBottomNav(
        selectedIndex: 3,
      ),
    );
  }

  Widget _errorUI(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 50, color: Colors.red),
        const SizedBox(height: 10),
        const Text(
          "Este video no se puede reproducir aquí",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoWebViewScreen(videoId: videoId),
              ),
            );
          },
          child: const Text("Ver en navegador"),
        )
      ],
    );
  }
}
