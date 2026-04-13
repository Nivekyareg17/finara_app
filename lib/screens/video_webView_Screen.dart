import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/translate_widget.dart';

class VideoWebViewScreen extends StatelessWidget {
  final String videoId;

  const VideoWebViewScreen({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final url = "https://www.youtube.com/watch?v=$videoId";

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText("Video"),
        titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 10, 109, 82),
            fontWeight: FontWeight.bold,
            fontSize: 18),
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
