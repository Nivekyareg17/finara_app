import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final int userId;
  final String fallbackName;
  final String? fallbackImageUrl;
  final String? fallbackDescription;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.fallbackName,
    this.fallbackImageUrl,
    this.fallbackDescription,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? user;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      return;
    }

    final data = await ApiService.getPublicUserProfile(token, widget.userId);
    if (!mounted) return;

    setState(() {
      user = data ??
          {
            "id": widget.userId,
            "name": widget.fallbackName,
            "description": widget.fallbackDescription,
            "profile_image_url": widget.fallbackImageUrl,
          };
      isLoading = false;
      hasError = false;
    });
  }

  String get displayName {
    final name = user?["name"]?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return widget.fallbackName.trim().isEmpty ? "Usuario" : widget.fallbackName;
  }

  String get username {
    final value = user?["username"]?.toString().trim();
    return value == null || value.isEmpty ? "" : "@$value";
  }

  String get description {
    final value = user?["description"]?.toString().trim();
    if (value == null || value.isEmpty) {
      return "Este usuario aún no tiene descripción.";
    }
    return value;
  }

  ImageProvider? _profileImageProvider() {
    final rawUrl =
        user?["profile_image_url"]?.toString().trim().isNotEmpty == true
            ? user!["profile_image_url"].toString().trim()
            : widget.fallbackImageUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return null;

    if (rawUrl.startsWith("data:")) {
      try {
        final commaIndex = rawUrl.indexOf(",");
        if (commaIndex == -1) return null;
        final imageData = rawUrl.substring(commaIndex + 1).split("?").first;
        return MemoryImage(base64Decode(imageData));
      } catch (_) {
        return null;
      }
    }

    if (!kIsWeb && rawUrl.startsWith("file:")) return null;

    final normalized = rawUrl.startsWith("http")
        ? rawUrl
        : "${ApiService.baseUrl}${rawUrl.startsWith("/") ? "" : "/"}$rawUrl";
    return NetworkImage(normalized);
  }

  Widget _avatar(double size) {
    final imageProvider = _profileImageProvider();
    final fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE2E8F0),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.48,
        color: const Color(0xFF64748B),
      ),
    );

    if (imageProvider == null) return fallback;

    return ClipOval(
      child: Image(
        image: imageProvider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxWidth = MediaQuery.of(context).size.width > 680 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF071A16) : const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text("Perfil"),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF071A16) : const Color(0xFFF6F8F7),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _avatar(132),
                          const SizedBox(height: 22),
                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (username.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              username,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade900 : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
