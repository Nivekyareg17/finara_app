import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/languaje_provider.dart';
import '../widgets/translate_widget.dart';
import '../services/pdf_service.dart';
import '../providers/finance_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: TranslatedText(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF064E3B)),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: TranslatedText(
                "Opciones",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),

          //MODO OSCURO
          _buildDrawerItem(
            icon: isDark ? Icons.light_mode : Icons.dark_mode,
            title: isDark ? "Modo claro" : "Modo oscuro",
            color: Colors.amber,
            onTap: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),

          const Divider(height: 20),

          _buildDrawerItem(
            icon: Icons.picture_as_pdf,
            title: "Descargar movimientos",
            color: Colors.blue,
            onTap: () async {
              final finance = context.read<FinanceProvider>();
              final auth = context.read<AuthProvider>();

              final user = await auth.getUserData();

              if (user == null) return;

              PdfService.exportTransactionsPdf(
                transactions: finance.transactions,
                name: user["name"] ?? "Sin nombre",
                email: user["email"] ?? "Sin email",
                getCategoryName: finance.getCategoryName,
                formatCurrency: finance.formatCurrency,
                balance: finance.balance,
              );
            },
          ),

          const Divider(height: 20),

          //IDIOMA
          Consumer<LanguageProvider>(
            builder: (context, langProvider, child) {
              return _buildDrawerItem(
                icon: Icons.translate,
                title: "Idioma de la App",
                subtitle: "Actual: ${langProvider.currentLanguageName}",
                color: const Color(0xFF00C853),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: TranslatedText(
                              "Selecciona Idioma",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: langProvider.supportedLanguages.length,
                              itemBuilder: (context, index) {
                                String key = langProvider
                                    .supportedLanguages.keys
                                    .elementAt(index);
                                String name =
                                    langProvider.supportedLanguages[key]!;

                                return ListTile(
                                  title: Text(name),
                                  trailing: langProvider.currentLanguage == key
                                      ? const Icon(Icons.check,
                                          color: Colors.green)
                                      : null,
                                  onTap: () {
                                    langProvider.setLanguage(key);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          const Divider(height: 20),

          //LOGOUT
          _buildDrawerItem(
            icon: Icons.logout,
            title: "Cerrar sesión",
            color: Colors.red,
            onTap: () async {
              Navigator.pop(context);

              final auth = context.read<AuthProvider>();
              await auth.logout();

              if (!context.mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                "/login",
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
