import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/languaje_provider.dart';
import '../widgets/translate_widget.dart';
import '../services/pdf_service.dart';
import '../services/api_service.dart';
import '../providers/finance_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String baseCurrency = "COP";

  static const Map<String, String> supportedCurrencies = {
    "COP": "Peso colombiano",
    "USD": "Dolar estadounidense",
    "EUR": "Euro",
    "MXN": "Peso mexicano",
    "ARS": "Peso argentino",
    "BRL": "Real brasileno",
    "GBP": "Libra esterlina",
    "CAD": "Dolar canadiense",
    "CLP": "Peso chileno",
    "PEN": "Sol peruano",
    "JPY": "Yen japones",
    "CHF": "Franco suizo",
  };

  static const Map<String, String> currencySymbols = {
    "COP": "\$",
    "USD": "US\$",
    "EUR": "€",
    "MXN": "MX\$",
    "ARS": "AR\$",
    "BRL": "R\$",
    "GBP": "£",
    "CAD": "CA\$",
    "CLP": "CLP\$",
    "PEN": "S/",
    "JPY": "¥",
    "CHF": "CHF",
  };

  @override
  void initState() {
    super.initState();
    loadUser();
    _loadBaseCurrency();
  }

  Future<void> _loadBaseCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      baseCurrency = (prefs.getString("base_currency") ?? "COP").toUpperCase();
    });
  }

  String _currencyLabel(String code) {
    final normalized = code.toUpperCase();
    final name = supportedCurrencies[normalized] ?? normalized;
    return "$normalized - $name";
  }

  Future<void> _selectBaseCurrency() async {
    final selected = await _showCurrencyPicker(baseCurrency);
    if (selected == null || selected == baseCurrency) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("base_currency", selected);
    if (!mounted) return;
    setState(() => baseCurrency = selected);
  }

  Future<String?> _showCurrencyPicker(String currentCurrency) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF10231E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Moneda",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                  children: [
                    ...supportedCurrencies.entries.map((entry) {
                      final selected = entry.key == currentCurrency;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFE2E8F0),
                          child: Text(
                            currencySymbols[entry.key] ?? entry.key,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text(entry.value),
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981))
                            : null,
                        onTap: () => Navigator.pop(context, entry.key),
                      );
                    }),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(Icons.add_rounded, color: Colors.black87),
                      ),
                      title: const Text(
                        "Otra moneda",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle:
                          const Text("Escribe un codigo ISO, ej: DOP, UYU, CNY"),
                      onTap: () async {
                        final custom = await _askCustomCurrency();
                        if (custom != null && context.mounted) {
                          Navigator.pop(context, custom);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _askCustomCurrency() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Agregar moneda"),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
                decoration: InputDecoration(
                  labelText: "Codigo ISO",
                  hintText: "Ej: USD",
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim().toUpperCase();
                    if (!RegExp(r'^[A-Z]{3}$').hasMatch(value)) {
                      setStateDialog(() {
                        errorText = "Usa 3 letras, por ejemplo COP";
                      });
                      return;
                    }
                    Navigator.pop(context, value);
                  },
                  child: const Text("Usar"),
                ),
              ],
            );
          },
        );
      },
    );
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
        if (commaIndex == -1) return null;
        final imageData = imageUrl.substring(commaIndex + 1).split("?").first;
        return MemoryImage(
          base64Decode(imageData),
        );
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(imageUrl);
  }

  Future<void> _pickImage() async {
    final auth = context.read<AuthProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (picked == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var loaderOpen = true;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/users/upload-profile-picture'),
      );
      request.headers['Authorization'] = 'Bearer ${auth.token}';

      final bytes = await picked.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: picked.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted && loaderOpen) {
        Navigator.pop(context);
        loaderOpen = false;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final uploadedUrl = data["url"]?.toString() ?? "";
        setState(() {
          profileImageUrl = uploadedUrl.startsWith("data:image")
              ? uploadedUrl
              : "$uploadedUrl?v=${DateTime.now().millisecondsSinceEpoch}";
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto de perfil actualizada")),
        );
      } else {
        throw "Error del servidor: ${response.statusCode}";
      }
    } catch (e) {
      if (mounted && loaderOpen) {
        Navigator.pop(context);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir imagen: $e")),
      );
    }
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
            icon: Icons.currency_exchange_rounded,
            title: "Moneda",
            subtitle: _currencyLabel(baseCurrency),
            color: const Color(0xFF10B981),
            onTap: () {
              Navigator.pop(context);
              _selectBaseCurrency();
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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/home",
                  (route) => false,
                );
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
