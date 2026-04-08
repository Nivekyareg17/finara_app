import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;

  const VideoPlayerScreen({super.key, required this.url});

  @override
 State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController controller;
  bool hasError = false;

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
      return '';
    }
  }

  Future<void> openYoutube() async {
    final Uri uri = Uri.parse(widget.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();

    final id = getVideoId(widget.url);

    if (id.isEmpty) {
      hasError = true;
      return;
    }

    controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    controller.loadVideoById(videoId: id);

    //Detectar errores automáticamente
    controller.listen((event) {
      if (event.playerState == PlayerState.unknown) {
        setState(() {
          hasError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    if (!hasError) controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reproduciendo")),
      body: Center(
        child: hasError
            ? _errorUI()
            : AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(controller: controller),
              ),
      ),
    );
  }

  //UI de error
  Widget _errorUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 60, color: Colors.grey),
        const SizedBox(height: 10),
        const Text(
          "Este video no se puede reproducir aquí",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: openYoutube,
          icon: const Icon(Icons.open_in_new),
          label: const Text("Ver en YouTube"),
        ),
      ],
    );
  }
}