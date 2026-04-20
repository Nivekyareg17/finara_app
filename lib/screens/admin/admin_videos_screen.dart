import 'package:flutter/material.dart';
import '../../widgets/translate_widget.dart';

class AdminVideosScreen extends StatelessWidget {
  const AdminVideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText("Gestionar videos"),
      ),
      body: const Center(
        child: TranslatedText(
          "Aquí podrás crear, editar y eliminar videos",
        ),
      ),
    );
  }
}