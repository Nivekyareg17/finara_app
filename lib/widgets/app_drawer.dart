import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/languaje_provider.dart';
import '../widgets/translate_widget.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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

          // 🌙 MODO OSCURO
          ListTile(
            leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            title: Text(isDark ? "Modo claro" : "Modo oscuro"),
            onTap: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),

          // 🌍 IDIOMA
          Consumer<LanguageProvider>(
            builder: (context, langProvider, child) {
              return ListTile(
                leading: const Icon(Icons.translate, color: Color(0xFF00C853)),
                title: const TranslatedText("Idioma de la App"),
                subtitle:
                    Text("Actual: ${langProvider.currentLanguageName}"),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor:
                        Theme.of(context).scaffoldBackgroundColor,
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
                              itemCount:
                                  langProvider.supportedLanguages.length,
                              itemBuilder: (context, index) {
                                String key = langProvider
                                    .supportedLanguages.keys
                                    .elementAt(index);
                                String name =
                                    langProvider.supportedLanguages[key]!;

                                return ListTile(
                                  title: Text(name),
                                  trailing:
                                      langProvider.currentLanguage == key
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

          // 🚪 LOGOUT
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const TranslatedText("Cerrar sesión"),
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