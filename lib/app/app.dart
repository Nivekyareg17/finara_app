import 'package:flutter/material.dart';
import 'router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finara App',
      debugShowCheckedModeBanner: false,
      
      // Configuramos el tema oscuro global para que combine con tus mockups
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: const Color(0xFF2ECC71), // Tu verde esmeralda
      ),

      // Definimos la ruta inicial (el chat de la IA)
      initialRoute: '/',
      
      // Usamos las rutas que definiste en el archivo router.dart
      routes: AppRouter.getRoutes(),
    );
  }
}