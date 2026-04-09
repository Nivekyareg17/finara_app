import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../widgets/custom_bottom_nav.dart';

class VideoWebViewScreen extends StatelessWidget {
  final String videoId;

  const VideoWebViewScreen({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final url = "https://www.youtube.com/embed/$videoId";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Video"),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(url),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(
        selectedIndex: 3,
      ),
    );
  }
}