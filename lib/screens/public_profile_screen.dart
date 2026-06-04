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

  bool get hasDescription {
    final value = user?["description"]?.toString().trim();
    return value != null && value.isNotEmpty;
  }

  String get description {
    final value = user?["description"]?.toString().trim();
    if (value == null || value.isEmpty) {
      return "Este usuario aun no tiene descripcion.";
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
    final maxWidth =
        MediaQuery.of(context).size.width > 680 ? 560.0 : double.infinity;
    final bg = isDark ? const Color(0xFF071A16) : const Color(0xFFF4F8F6);
    final surface = isDark ? const Color(0xFF10231F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Perfil"),
        elevation: 0,
        backgroundColor: bg,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
                  ? Center(
                      child: Text(
                        "No se pudo cargar el perfil.",
                        style: TextStyle(color: mutedColor),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF12352E),
                                        const Color(0xFF0B1F1B),
                                      ]
                                    : [
                                        const Color(0xFFE9FFF6),
                                        Colors.white,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFD7EFE6),
                              ),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF0F8F5F)
                                            .withOpacity(0.10),
                                        blurRadius: 22,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.45),
                                      width: 2,
                                    ),
                                  ),
                                  child: _avatar(124),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  displayName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (username.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      username,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.045),
                                        blurRadius: 14,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.14),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        hasDescription
                                            ? Icons.notes_rounded
                                            : Icons.info_outline_rounded,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        hasDescription
                                            ? "Descripcion"
                                            : "Sin descripcion",
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color:
                                        hasDescription ? textColor : mutedColor,
                                    fontSize: 16,
                                    height: 1.55,
                                    fontWeight: hasDescription
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                                ),
                              ],
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
