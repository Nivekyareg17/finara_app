import 'package:flutter/material.dart';
// Asegúrate de que este import coincida con la ruta de tu archivo de vista
import '../features/ai/view/ai_chat_page.dart'; 

class AppRouter {
  // Definimos las rutas estáticas
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) => const AIChatPage(), // Esta es la pantalla de Daiko IA
      // Cuando crees más pantallas, las pondrás aquí abajo:
      // '/login': (context) => const LoginPage(),
    };
  }
}