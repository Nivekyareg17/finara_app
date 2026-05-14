import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/languaje_provider.dart';
import '../widgets/translate_widget.dart';
import '../services/pdf_service.dart';
import '../providers/finance_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? profileImageUrl;
  String name = "";
  String email = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.getUserData();

    if (!mounted) return;

    setState(() {
      name = data?["name"] ?? "Sin nombre";
      email = data?["email"] ?? "Sin email";
      profileImageUrl = data?["profile_image_url"];
    });
  }

  ImageProvider? _profileImageProvider() {
    final imageUrl = profileImageUrl;

    if (imageUrl == null || imageUrl.isEmpty) return null;

    if (imageUrl.startsWith("data:image")) {
      try {
        final commaIndex = imageUrl.indexOf(",");
        return MemoryImage(
          base64Decode(imageUrl.substring(commaIndex + 1)),
        );
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(imageUrl);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      profileImageUrl = picked.path;
    });
  }

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
    final auth = context.watch<AuthProvider>();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF064E3B),
            ),
            currentAccountPicture: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white12,
                  backgroundImage: _profileImageProvider(),
                  child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                      ? const Icon(Icons.person,
                          size: 40, color: Colors.white54)
                      : null,
                ),

                // BTN CAMBIAR FOTO
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C853),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            accountName: Text(
              name.isEmpty ? "Cargando..." : name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white),
            ),
            accountEmail: Text(
              email.isEmpty ? "Cargando..." : email,
              style: const TextStyle(color: Colors.white70),
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

          if (auth.isAdmin)
            _buildDrawerItem(
              icon: Icons.swap_horiz,
              title: auth.isAdminView
                  ? "Cambiar a vista cliente"
                  : "Volver a vista admin",
              color: Colors.purple,
              onTap: () {
                auth.toggleView();
                Navigator.pop(context);
              },
            ),

          

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
