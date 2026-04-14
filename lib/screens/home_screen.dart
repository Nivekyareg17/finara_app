import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finara_app_v1/screens/stock_screen.dart';
import '../providers/languaje_provider.dart'; // Asegúrate que el nombre del archivo sea este
import '../widgets/QuickActionTile.dart';
import '../widgets/quick_wins.dart';
import '../widgets/statcard.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/translate_widget.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el provider sin escuchar cambios constantes aquí (listen: false)
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder(
      // 2. Ejecutamos la carga inicial del idioma
      future: langProvider.ensureInitialized(),
      builder: (context, snapshot) {
        
        // 3. Mientras carga (estos son los 2 segundos de delay)
        // Mostramos un fondo sólido con un cargador elegante
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF061A17) : const Color(0xFFF5F3F3),
            body: const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(6, 78, 59, 1),
              ),
            ),
          );
        }

        // 4. UNA VEZ CARGADO: Mostramos la UI real
        // Aquí ya NO hay parpadeo porque el Scaffold se dibuja con los datos listos
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF061A17) : const Color(0xFFF5F3F3),
          appBar: AppBar(
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Image.asset(
                  "assets/images/Logo_finara.png",
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance,
                      color: Color.fromRGBO(6, 78, 59, 1)),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Finara",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 10, 109, 82),
                  ),
                ),
              ],
            ),
          ),
          drawer: const AppDrawer(),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // ESTADÍSTICAS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: langProvider.currentLanguage == 'zh' ? "已完成" : "COMPLETADO",
                        count: "24",
                        unit: langProvider.currentLanguage == 'zh' ? "课程" : "Lecciones",
                        icon: Icons.emoji_events_outlined,
                        accentColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: langProvider.currentLanguage == 'zh' ? "AI 积分" : "CRÉDITOS IA",
                        count: "850",
                        unit: langProvider.currentLanguage == 'zh' ? "剩余" : "Restantes",
                        icon: Icons.auto_awesome,
                        accentColor: const Color(0xFF2ECC71),
                      ),
                    ),
                  ],
                ),
              ),

              const FinaraQuickWins(),
              const SizedBox(height: 25),

              // TÍTULO DE SECCIÓN CON TRADUCCIÓN DINÁMICA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  langProvider.currentLanguage == 'zh' ? "快速操作" : "ACCIONES RÁPIDAS",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ACCESO AL CHAT IA
              QuickActionTile(
                title: langProvider.currentLanguage == 'zh' ? "咨询 Finara AI" : "Pregunta a Finara AI",
                subtitle: langProvider.currentLanguage == 'zh' ? "24/7 专家建议" : "Asesoría experta 24/7",
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF1E8449),
                onTap: () => Navigator.pushReplacementNamed(context, "/daiko_ai"),
              ),

              // VISTA DE MERCADO
              QuickActionTile(
                title: langProvider.currentLanguage == 'zh' ? "股票市场" : "Mercado de Valores",
                subtitle: langProvider.currentLanguage == 'zh' ? "查看实时价格" : "Ver precios en vivo",
                icon: Icons.show_chart,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StocksScreen(),
                    ),
                  );
                },
              ),

              // RUTA DE APRENDIZAJE
              QuickActionTile(
                title: langProvider.currentLanguage == 'zh' ? "学习路线" : "Ruta de Aprendizaje",
                subtitle: langProvider.currentLanguage == 'zh' ? "今天有 3 个模块待完成" : "3 módulos para completar hoy",
                icon: Icons.school_outlined,
                iconColor: Colors.purple,
                onTap: () => Navigator.pushReplacementNamed(context, "/video"),
              ),

              const SizedBox(height: 80),
            ],
          ),
          bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
        );
      },
    );
  }
}