import 'package:finara_app_v1/screens/calculators/calculators_screen.dart';
import 'package:finara_app_v1/screens/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finara_app_v1/screens/stock_screen.dart';
import '../providers/languaje_provider.dart';
import '../providers/auth_provider.dart'; // <-- IMPORTANTE: Agregar esto para sacar token y nombre
import '../widgets/QuickActionTile.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/quick_wins.dart';
import '../widgets/statcard.dart';
import 'chat_list_screen.dart';
import '../widgets/calculators_card.dart';
import '../features/ai/service/ai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  // Función para abrir el panel elegante con los modelos y consultar los créditos
  void _mostrarDetallesModelos(BuildContext context, LanguageProvider lang, bool isDark) {
    // Obtenemos los datos del usuario actual
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String token = authProvider.token ?? "";
    final String userNameReal = authProvider.userName ?? "Usuario";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0A1F1C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 25,
              bottom: MediaQuery.of(context).viewInsets.bottom + 25
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            
                Text(
                  lang.currentLanguage == 'zh' ? "AI 积分 (每日限制)" : "Tus Créditos IA (Límites diarios)",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                Divider(color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 10),

                
                FutureBuilder<Map<String, int>>(
                  future: AIService().obtenerCreditosDeUsuario(token, userNameReal),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2ECC71)),
                        ),
                      );
                    }

                
                    final creditos = snapshot.data ?? {};
                    final int cPensar = creditos['pensar'] ?? 0;
                    final int cBolsa = creditos['bolsa'] ?? 0;
                    final int cGastos = creditos['gastos'] ?? 0;
                    final int cRapido = creditos['rapido'] ?? 0;

                    return Column(
                      children: [
                        _buildModelTile(
                          icon: Icons.psychology,
                          title: "Pensar",
                          subtitle: "Razonamiento profundo",
                          color: Colors.purpleAccent,
                          creditosRestantes: cPensar,
                          isDark: isDark
                        ),
                        _buildModelTile(
                          icon: Icons.candlestick_chart,
                          title: "Bolsa",
                          subtitle: "Análisis de mercado",
                          color: Colors.blueAccent,
                          creditosRestantes: cBolsa,
                          isDark: isDark
                        ),
                        _buildModelTile(
                          icon: Icons.account_balance_wallet,
                          title: "Gastos",
                          subtitle: "Auditoría financiera",
                          color: Colors.orangeAccent,
                          creditosRestantes: cGastos,
                          isDark: isDark
                        ),
                        _buildModelTile(
                          icon: Icons.bolt,
                          title: "Rápido",
                          subtitle: "Respuestas ágiles",
                          color: Colors.yellowAccent,
                          creditosRestantes: cRapido,
                          isDark: isDark
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildModelTile({required IconData icon, required String title, required String subtitle, required Color color, required int creditosRestantes, required bool isDark}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: creditosRestantes > 0 ? const Color(0xFF2ECC71).withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "$creditosRestantes",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: creditosRestantes > 0 ? const Color(0xFF2ECC71) : Colors.redAccent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder(
      future: langProvider.ensureInitialized(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF061A17) : const Color(0xFFF5F3F3),
            body: const Center(
              child: CircularProgressIndicator(color: Color.fromRGBO(6, 78, 59, 1)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF061A17) : const Color(0xFFF5F3F3),
          bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
          appBar: AppBar(
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Image.asset(
                  "assets/images/Logo_finara.png",
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, color: Color.fromRGBO(6, 78, 59, 1)),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Finara",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 10, 109, 82)),
                ),
              ],
            ),
            actions: [
              // <-- NUEVO BOTÓN SUTIL (!) EN LA APPBAR -->
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.priority_high, size: 16, color: Colors.grey),
                  ),
                  tooltip: 'Ver Créditos IA',
                  onPressed: () {
                    _mostrarDetallesModelos(context, langProvider, isDark);
                  },
                ),
              )
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
         
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    
                    Expanded(
                      child: StatCard(
                        title: "MENSAJES",
                        count: "💬",
                        unit: "Chats",
                        icon: Icons.chat,
                        accentColor: Colors.green,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const FinaraQuickWins(),
              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  langProvider.currentLanguage == 'zh' ? "快速操作" : "ACCIONES RÁPIDAS",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
              ),

              const SizedBox(height: 16),

              QuickActionTile(
                title: langProvider.currentLanguage == 'zh' ? "咨询 Finara AI" : "Pregunta a Finara AI",
                subtitle: langProvider.currentLanguage == 'zh' ? "24/7 专家建议" : "Asesoría experta 24/7",
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF1E8449),
                onTap: () => Navigator.pushReplacementNamed(context, "/daiko_ai"),
              ),

              QuickActionTile(
                title: langProvider.currentLanguage == 'zh' ? "股票市场" : "Mercado de Valores",
                subtitle: langProvider.currentLanguage == 'zh' ? "查看实时价格" : "Ver precios en vivo",
                icon: Icons.show_chart,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StocksScreen()));
                },
              ),

              QuickActionTile(
                title: langProvider.currentLanguage == 'zh' ? "学习路线" : "Ruta de Aprendizaje",
                subtitle: langProvider.currentLanguage == 'zh' ? "今天有 3 个模块待完成" : "3 módulos para completar hoy",
                icon: Icons.school_outlined,
                iconColor: Colors.purple,
                onTap: () => Navigator.pushReplacementNamed(context, "/video"),
              ),

              CalculatorsCard(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorsScreen()));
                },
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}