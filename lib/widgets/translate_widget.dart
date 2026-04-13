import 'package:finara_app_v1/providers/languaje_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/languaje_provider.dart'; 

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;           // <--- AGREGA ESTO
  final TextOverflow? overflow; // <--- AGREGA ESTO

  const TranslatedText(
    this.text, {
    super.key, 
    this.style, 
    this.textAlign,
    this.maxLines, // <--- Y ESTO
    this.overflow, // <--- Y ESTO
  });

  @override
  Widget build(BuildContext context) {
    final langProv = context.watch<LanguageProvider>();

    return FutureBuilder<String>(
      key: ValueKey('${langProv.currentLanguage}_$text'),
      future: langProv.translate(text),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines, // <--- PÁSALO AL TEXT REAL
          overflow: overflow, // <--- PÁSALO AL TEXT REAL
        );
      },
    );
  }
}