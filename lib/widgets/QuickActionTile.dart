import 'package:flutter/material.dart';
// 1. Importamos el widget traductor
import 'translate_widget.dart'; 

class QuickActionTile extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _active = true),
        onExit: (_) => setState(() => _active = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _active = true),
          onTapCancel: () => setState(() => _active = false),
          onTapUp: (_) => setState(() => _active = false),
          child: AnimatedScale(
            scale: _active ? 1.025 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121212) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withOpacity(_active ? 0.18 : 0.05),
                      blurRadius: _active ? 18 : 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(_active ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(widget.icon, color: widget.iconColor),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. CAMBIO: Título de la acción traducido
                    TranslatedText(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    // 3. CAMBIO: Subtítulo traducido (ej: "Asesoría experta" -> "Expert advice")
                    TranslatedText(
                      widget.subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
