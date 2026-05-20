import 'package:flutter/material.dart';
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

  void _setActive(bool value) {
    if (_active == value) return;
    setState(() => _active = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: MouseRegion(
        onEnter: (_) => _setActive(true),
        onExit: (_) => _setActive(false),
        child: GestureDetector(
          onTapDown: (_) => _setActive(true),
          onTapCancel: () => _setActive(false),
          onTapUp: (_) => _setActive(false),
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
                      color:
                          widget.iconColor.withOpacity(_active ? 0.18 : 0.05),
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
                        color:
                            widget.iconColor.withOpacity(_active ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(widget.icon, color: widget.iconColor),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          TranslatedText(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
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
