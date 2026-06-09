import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../widgets/translate_widget.dart';

class VideoWebViewScreen extends StatefulWidget {
  final String videoId;

  const VideoWebViewScreen({super.key, required this.videoId});

  @override
  State<VideoWebViewScreen> createState() => _VideoWebViewScreenState();
}

class _VideoWebViewScreenState extends State<VideoWebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final url = "https://www.youtube.com/watch?v=${widget.videoId}";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores basados en el diseño de tu video_list_screen.dart
    final backgroundColor = isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8F7);
    const primaryColor = Color.fromARGB(255, 10, 109, 82);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        iconTheme: const IconThemeData(color: primaryColor),
        title: const TranslatedText("Video"),
        titleTextStyle: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18),
      ),
      body: Stack(
        children: [
          // 1. Capa del WebView principal
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(url),
            ),
            initialSettings: InAppWebViewSettings(
              transparentBackground: true, // Evita destellos blancos/negros raros
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
            },
            onReceivedError: (controller, request, error) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            },
          ),

          // 2. Capa de carga UX (Evita que se quede en negro al inicio)
          if (_isLoading && !_hasError)
            Container(
              color: backgroundColor,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ),

          // 3. Capa UX de Error de Internet
          if (_hasError)
            _buildErrorWidget(context, isDark, backgroundColor),
        ],
      ),
    );
  }

  // Widget personalizado para un diseño limpio de "Sin conexión"
  Widget _buildErrorWidget(BuildContext context, bool isDark, Color bgColor) {
    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0A6D52).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFF0A6D52),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          TranslatedText(
            "Sin conexión a internet",
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            "Por favor, verifica tu conexión e inténtalo de nuevo.",
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
              _webViewController?.reload(); // Intenta recargar la página
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const TranslatedText("Reintentar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6D52),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}