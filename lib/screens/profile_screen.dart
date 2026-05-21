import 'package:finara_app_v1/models/category_model.dart';
import 'package:finara_app_v1/providers/auth_provider.dart';
import 'package:finara_app_v1/screens/calculators/calculators_screen.dart';
import 'package:finara_app_v1/widgets/custom_bottom_nav.dart';
import 'package:finara_app_v1/widgets/translate_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finara_app_v1/providers/theme_provider.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:finara_app_v1/providers/languaje_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

import 'package:finara_app_v1/models/meta_ahorro.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    // Quita cualquier cosa que no sea nÃºmero
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Convierte a nÃºmero y formatea (ejemplo: 1000 -> 1.000)
    double value = double.parse(newText) / 100; // Divide por 100 para centavos
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    String formatted = formatter.format(value).trim();

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Map<String, dynamic> _getCategoryData(String description) {
  // Comparamos la descripcion para asignar icono y color
  String desc = description.toLowerCase();
  if (desc.contains("mercado")) {
    return {'icon': Icons.shopping_basket_rounded, 'color': Colors.orange};
  } else if (desc.contains("pago") || desc.contains("trabajo")) {
    return {'icon': Icons.work_rounded, 'color': Colors.blue};
  } else if (desc.contains("ahorro")) {
    return {'icon': Icons.savings_rounded, 'color': Colors.pink};
  } else if (desc.contains("gasto") || desc.contains("adicional")) {
    return {'icon': Icons.add_circle_outline_rounded, 'color': Colors.purple};
  }
  return {'icon': Icons.category_rounded, 'color': Colors.grey};
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NumberFormat formatter = NumberFormat("#,##0.00", "en_US");

  String? profileImageUrl;
  String name = "";
  String email = "";
  String username = "";
  String age = "";
  String description = "";
  String phone = "";

  List<TransactionModel> transactions = [];
  List<CategoryModel> categories = [];

  String selectedChartType = "gasto";

  @override
  void initState() {
    super.initState();
    loadUser();
    _loadData();
  }

  Future<void> loadTransactions() async {
    final auth = context.read<AuthProvider>();

    final data = await ApiService.getTransactions(auth.token!);

    print(data);

    try {
      final loadedTransactions =
          data.map((e) => TransactionModel.fromMap(e)).toList();

      print("TRANSACCIONES OK");

      if (!mounted) return;

      setState(() {
        transactions = loadedTransactions;
      });
    } catch (e) {
      print("ERROR PARSEANDO TRANSACCIONES");
      print(e);
    }
  }

  void loadUser() async {
    try {
      final auth = context.read<AuthProvider>();
      final data = await auth.getUserData();
      print(data);

      setState(() {
        if (data != null) {
          name = data["name"] ?? "Sin nombre";
          email = data["email"] ?? "Sin email";
          profileImageUrl = data["profile_image_url"];
          username = data["username"] ?? "";
          age = data["age"]?.toString() ?? "";
          description = data["description"] ?? "";
          phone = data["phone"] ?? "";
        } else {
          name = "No se pudo cargar";
          email = "";
        }
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        name = "Error cargando";
        email = "";
      });
    }
  }

  Future<void> _loadData() async {
    await loadCategories();
    await loadTransactions();
  }

  Future<void> loadCategories() async {
    final auth = context.read<AuthProvider>();
    final data = await ApiService.getTransactionCategories(auth.token!);

    if (!mounted) return;

    setState(() {
      categories = data.map((e) => CategoryModel.fromMap(e)).toList();
    });
  }

  String getCategoryName(int categoryId) {
    try {
      return categories
          .firstWhere(
            (c) => int.parse(c.id) == categoryId,
          )
          .name;
    } catch (e) {
      return "General";
    }
  }

  double getBalance() {
    double total = 0;

    for (var t in transactions) {
      if (t.type == "ingreso") {
        total += t.amount;
      } else {
        total -= t.amount;
      }
    }

    return total;
  }

  double getTotalIngresos() {
    return transactions
        .where((t) => t.type == "ingreso")
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalGastos() {
    return transactions
        .where((t) => t.type == "gasto")
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalGeneral() {
    return getTotalIngresos() + getTotalGastos();
  }

  Map<String, double> getGastosPorCategoria() {
    Map<String, double> data = {};

    for (var t in transactions) {
      if (t.type == "gasto") {
        String categoria = getCategoryName(int.tryParse(t.categoryId) ?? 0);

        data[categoria] = (data[categoria] ?? 0) + t.amount;
      }
    }

    return data;
  }

  Map<String, double> getMovimientosPorCategoria(String tipo) {
    Map<String, double> data = {};

    for (var t in transactions) {
      if (t.type == tipo) {
        String categoria = getCategoryName(
          int.tryParse(
                t.categoryId,
              ) ??
              0,
        );

        data[categoria] = (data[categoria] ?? 0) + t.amount;
      }
    }

    final sorted = data.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return Map.fromEntries(sorted);
  }

  Color getCategoryColor(String categoria) {
    String c = categoria.toLowerCase();

    if (c.contains("comida")) return Colors.orange;
    if (c.contains("mercado")) return Colors.deepOrange;
    if (c.contains("transporte")) return Colors.blue;
    if (c.contains("salud")) return Colors.red;
    if (c.contains("ahorro")) return Colors.green;
    if (c.contains("trabajo")) return Colors.indigo;
    if (c.contains("educacion")) return Colors.purple;

    return const Color(0xFF00C853);
  }

  @override
  Widget build(BuildContext context) {
    final metas = context.watch<AuthProvider>().metas;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 4),

      // APPBAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.transparent, // Fondo transparente para mayor fluidez
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            // Logo o Icono de la marca con un degradado sutil
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                    12), // Bordes mas redondeados son tendencia
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Finara", // Nombre de la App
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1B4332),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "Mi Perfil", // Subtitulo indicativo
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      //DRAWER (MENU)
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // HEADER PERSONALIZADO
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF064E3B),
              ),
              currentAccountPicture: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white24,
                          width: 2), // Un borde lo hace ver mas fino
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white12,
                      // Usamos un try-catch visual con errorBuilder si fuera necesario,
                      // pero aqui­ optimizamos la logica de carga
                      backgroundImage: (profileImageUrl != null &&
                              profileImageUrl!.isNotEmpty)
                          ? NetworkImage(profileImageUrl!)
                          : null,
                      child:
                          (profileImageUrl == null || profileImageUrl!.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 40, color: Colors.white54)
                              : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: AnimatedContainer(
                        // Pequena animacion al tocar
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(
                            6), // Un poquito mÃ¡s grande para el dedo
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(
                            Icons
                                .camera_alt, // Camera_alt se entiende mejor que edit
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              accountName: Text(
                name.isEmpty ? "Cargando..." : name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white),
              ),
              accountEmail: Text(
                email.isEmpty ? "Cargando..." : email,
                style: const TextStyle(color: Colors.white70),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("CONFIGURACION",
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ),

                  // MODO OSCURO MEJORADO
                  _buildDrawerItem(
                    icon: isDark ? Icons.light_mode : Icons.dark_mode,
                    title: isDark ? "Modo claro" : "Modo oscuro",
                    color: Colors.orange,
                    onTap: () => context.read<ThemeProvider>().toggleTheme(),
                  ),

                  // IDIOMA MEJORADO
                  Consumer<LanguageProvider>(
                    builder: (context, langProvider, child) {
                      return _buildDrawerItem(
                        icon: Icons.translate,
                        title: "Idioma de la App",
                        subtitle: langProvider.currentLanguageName,
                        color: const Color(0xFF00C853),
                        onTap: () => _showLanguagePicker(context, langProvider),
                      );
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.badge_rounded,
                    title: "Informacion personal",
                    subtitle:
                        username.isEmpty ? "Completa tu perfil" : "@$username",
                    color: const Color(0xFFE1306C),
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileInfoSheet();
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.support_agent_rounded,
                    title: "Soporte",
                    subtitle: "Ayuda y contacto",
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(context);
                      _showSupportSheet();
                    },
                  ),
                ],
              ),
            ),

            // BOTÃ“N DE CERRAR SESIÃ“N
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.red.withOpacity(0.1),
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const TranslatedText("Cerrar sesion",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final auth = context.read<AuthProvider>();

                  await auth.logout();

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),

      //BODY CRUD
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                //PERFIL
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20, // Más pequeño
                      backgroundColor: Colors.white12,
                      // <-- ESTA ES LA CLAVE: Lee la MISMA variable 'profileImageUrl'
                      backgroundImage: (profileImageUrl != null &&
                              profileImageUrl!.isNotEmpty)
                          ? NetworkImage(profileImageUrl!)
                          : null,
                      child:
                          (profileImageUrl == null || profileImageUrl!.isEmpty)
                              ? const Icon(Icons.person_outline_rounded,
                                  size: 20, color: Colors.white54)
                              : null,
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? "Cargando..." : name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          email.isEmpty ? "Cargando..." : email,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // TARJETA DE BALANCE MEJORADA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24), // Un poco más de aire
                  decoration: BoxDecoration(
                    // Un degradado sutil lo hace ver más "Premium"
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                          : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Balance Total",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF1B4332).withOpacity(0.7),
                              fontSize: 16,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF1B4332).withOpacity(0.3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        formatCurrency(
                            getBalance()), // <-- Usando la función nueva
                        style: TextStyle(
                          fontSize: 36, // Un poco más grande
                          fontWeight: FontWeight.w900, // Más grueso
                          letterSpacing:
                              -1, // Un poco más juntas las letras se ve pro
                          color:
                              isDark ? Colors.white : const Color(0xFF1B4332),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Un pequeño indicador extra le da el toque final
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Actualizado hace un momento",
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF1B4332),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //SECCIÓN METAS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Metas de ahorro",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _crearMeta,
                      icon: const Icon(Icons.add, color: Color(0xFF00C853)),
                    )
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.34,
                  child: metas.isEmpty
                      ? const Center(child: Text("No hay metas aún"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: metas.length,
                          itemBuilder: (context, index) {
                            final meta = metas[index];

                            return Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color.fromARGB(255, 6, 78, 59)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isDark
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                        )
                                      ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (meta.imageData != null &&
                                      meta.imageData!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                      child: Image.memory(
                                        base64Decode(meta.imageData!),
                                        height: 100,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                  //CONTENIDO FLEXIBLE
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // NOMBRE + ICONOS
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  meta.nombre,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _agregarAporte(index),
                                                    child: const Icon(
                                                        Icons.add_circle,
                                                        color: Colors.green),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _editarMeta(index),
                                                    child: const Icon(
                                                        Icons.edit,
                                                        size: 18,
                                                        color: Color.fromARGB(
                                                            255, 5, 46, 35)),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _eliminarMeta(index),
                                                    child: const Icon(
                                                        Icons.delete,
                                                        size: 18,
                                                        color: Colors.red),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          LinearProgressIndicator(
                                            value: meta.progreso.clamp(0, 1),
                                            backgroundColor: Colors.grey[300],
                                            color: const Color(0xFF00C853),
                                          ),

                                          const SizedBox(height: 6),

                                          Text(
                                            "${meta.porcentaje.toStringAsFixed(1)}% completado",
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            "Llevas: ${formatCurrency(meta.montoActual)}",
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),

                                          Text(
                                            "Faltan: ${formatCurrency(meta.montoMeta - meta.montoActual)}",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.redAccent),
                                          ),

                                          Text(
                                            "Faltan: ${meta.mesesRestantes} meses",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 20),

                //TÍTULO Y BOTÓN AGREGAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const TranslatedText(
                      "Movimientos",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => showForm(),
                      icon: const Icon(Icons.add, color: Color(0xFF00C853)),
                      label: const TranslatedText("Agregar",
                          style: TextStyle(color: Color(0xFF00C853))),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Container(
                  height: 370,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Resumen financiero",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 210,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                centerSpaceRadius: 55,
                                sectionsSpace: 4,
                                centerSpaceColor: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                sections: [
                                  PieChartSectionData(
                                    value: getTotalIngresos(),
                                    color: Colors.green,
                                    radius: 65,
                                    title: getTotalGeneral() == 0
                                        ? "0%"
                                        : "${((getTotalIngresos() / getTotalGeneral()) * 100).toStringAsFixed(1)}%",
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: getTotalGastos(),
                                    color: Colors.redAccent,
                                    radius: 65,
                                    title: getTotalGeneral() == 0
                                        ? "0%"
                                        : "${((getTotalGastos() / getTotalGeneral()) * 100).toStringAsFixed(1)}%",
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Balance",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatCurrency(getBalance()),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Ingresos: ${formatCurrency(getTotalIngresos())}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Gastos: ${formatCurrency(getTotalGastos())}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedChartType = "ingreso";
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedChartType == "ingreso"
                                  ? const Color(0xFF00C853)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                "Ingresos",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedChartType = "gasto";
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedChartType == "gasto"
                                  ? Colors.redAccent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                "Gastos",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  height: 330,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 14,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final categorias = getMovimientosPorCategoria(
                              selectedChartType,
                            ).entries.toList();

                            final item = categorias[group.x];

                            return BarTooltipItem(
                              "${item.key}\n${formatCurrency(item.value)}",
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ),
                      alignment: BarChartAlignment.start,
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final categorias = getMovimientosPorCategoria(
                                selectedChartType,
                              ).keys.toList();

                              if (value.toInt() >= categorias.length) {
                                return const SizedBox();
                              }

                              return Text(
                                categorias[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                      ),
                      barGroups: getMovimientosPorCategoria(
                        selectedChartType,
                      ).entries.toList().asMap().entries.map((entry) {
                        int index = entry.key;
                        final item = entry.value;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: item.value,
                              color: getCategoryColor(
                                item.key,
                              ),
                              width: 22,
                              borderRadius: BorderRadius.circular(8),
                            )
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                //LISTA DE TRANSACCIONES
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    final bool isIngreso = t.type == "ingreso";
                    final bool isFuture = t.isFutureMovement;
                    final categoryName =
                        getCategoryName(int.tryParse(t.categoryId) ?? 0);
                    final catData = _getCategoryData(categoryName);
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isFuture
                            ? (isDark
                                ? const Color(0xFF172554)
                                : const Color(0xFFEFF6FF))
                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: isFuture
                            ? Border.all(color: const Color(0xFF3B82F6))
                            : null,
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10)
                              ],
                      ),
                      child: Row(
                        children: [
                          //ICON SEGÚN LA IMAGEN
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catData['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(catData['icon'],
                                color: catData['color'], size: 24),
                          ),
                          const SizedBox(width: 15),

                          //DESCRIPCIÓN Y FECHA
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.description,
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat("dd/MM/yyyy").format(t.date),
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                                if (isFuture) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      "Próximo movimiento",
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          //MONTO Y ACCIONES
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${isIngreso ? '+' : '-'} ${formatCurrency(t.amount)}",
                                style: TextStyle(
                                  color: isIngreso
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => showForm(edit: t),
                                    child: const Icon(Icons.edit_note,
                                        size: 20, color: Colors.blueGrey),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => confirmDelete(t),
                                    child: const Icon(Icons.delete_outline,
                                        size: 20, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showForm({TransactionModel? edit}) async {
    await loadCategories();
    List<CategoryModel> localCategories = List.from(categories);
    final today = DateTime.now();
    final selectedInitialDate = edit?.date ?? today;
    final dateController = TextEditingController(
        text: edit != null
            ? DateFormat("MM/dd/yyyy").format(selectedInitialDate)
            : DateFormat("MM/dd/yyyy").format(today));

    final desc = TextEditingController(text: edit?.description);
    final amount =
        TextEditingController(text: edit != null ? edit.amount.toString() : "");
    String type = edit?.type ?? "gasto";
    int? selectedCategoryId = int.tryParse(edit?.categoryId ?? "");
    bool allowFutureMovement = edit?.isFutureMovement ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        bool isLoadingDialog = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            final filteredCategories =
                localCategories.where((c) => c.type == type).toList();

            if (filteredCategories.isNotEmpty) {
              if (selectedCategoryId == null ||
                  !filteredCategories
                      .any((c) => int.parse(c.id) == selectedCategoryId)) {
                selectedCategoryId = int.parse(filteredCategories.first.id);
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  //BARRA SUPERIOR (Indicador de arrastre)
                  const SizedBox(height: 12),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TÃTULO
                          Center(
                            child: Text(
                              edit == null
                                  ? "Nuevo Movimiento"
                                  : "Editar Movimiento",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ), // Center
                          ),

                          const SizedBox(height: 25),

                          // SELECTOR GASTO / INGRESO
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey[100],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                _buildTypeButton(
                                    "gasto",
                                    type,
                                    (v) => setStateDialog(() {
                                          type = v;
                                        }),
                                    isDark),
                                _buildTypeButton(
                                    "ingreso",
                                    type,
                                    (v) => setStateDialog(() {
                                          type = v;
                                        }),
                                    isDark),
                              ],
                            ), // Row
                          ),

                          const SizedBox(height: 35),

                          // CAMPO MONTO

                          const Center(
                            child: TranslatedText(
                              "Ingresar monto",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextField(
                            controller: amount,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            style: const TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF064E3B),
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.attach_money,
                                  size: 35, color: Color(0xFF064E3B)),
                              hintText: "0.00",
                              border: InputBorder.none,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // SELECTOR CATEGORA
                          const TranslatedText("Categoria",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 10),

                          // 1. Btn para crear nueva
                          TextButton(
                            onPressed: () async {
                              String? nueva =
                                  await _mostrarDialogoCategoriaBonita();

                              if (nueva != null && nueva.isNotEmpty) {
                                // ValidaciÃ³n local: Usamos ignoreCase para mayor seguridad
                                if (localCategories.any((c) =>
                                    c.name.toLowerCase() ==
                                    nueva.toLowerCase())) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Esa categoria ya existe")),
                                  );
                                  return;
                                }

                                final auth = context.read<AuthProvider>();
                                // Asumimos que la API devuelve el objeto creado o al menos confirma el Ã©xito
                                bool success = await ApiService.createCategory(
                                    auth.token!, nueva, type);

                                if (success) {
                                  await loadCategories(); // Recarga la lista global 'categories'

                                  setStateDialog(() {
                                    // ACTUALIZACIÃ“N CRÃTICA:
                                    // 1. Sincronizamos la lista local con la global reciÃ©n cargada
                                    localCategories = List.from(categories);

                                    // 2. Filtramos inmediatamente para que el Dropdown vea el cambio
                                    final filtered = localCategories
                                        .where((c) => c.type == type)
                                        .toList();

                                    if (filtered.isNotEmpty) {
                                      // 3. Intentamos encontrar la que acabamos de crear por nombre
                                      // (Es mÃ¡s seguro que .last si la lista viene ordenada del servidor)
                                      final creada = filtered.firstWhere(
                                        (c) =>
                                            c.name.toLowerCase() ==
                                            nueva.toLowerCase(),
                                        orElse: () => filtered.last,
                                      );
                                      selectedCategoryId = int.parse(creada.id);
                                    }
                                  });
                                }
                              }
                            },
                            child: const Text("Agregar categoria",
                                style: TextStyle(color: Colors.green)),
                          ),

// 2. Fila con Dropdown + Editar + Eliminar
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black12
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(15),
                                    border:
                                        Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: DropdownButton<int>(
                                    value: selectedCategoryId,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    // IMPORTANTE: AsegÃºrate de que filteredCategories se re-calcule
                                    // antes de este punto en el build del diÃ¡logo.
                                    items: localCategories
                                        .where((c) =>
                                            c.type ==
                                            type) // Filtramos aquÃ­ directamente para evitar desfases
                                        .map((cat) {
                                      return DropdownMenuItem<int>(
                                        value: int.parse(cat.id),
                                        child: Text(cat.name),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      setStateDialog(
                                          () => selectedCategoryId = v);
                                    },
                                  ),
                                ),
                              ),
                              if (selectedCategoryId != null) ...[
                                // BOTÃ“N EDITAR
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueAccent),
                                  onPressed: () async {
                                    // Buscamos en localCategories directamente
                                    final catActual =
                                        localCategories.firstWhere(
                                      (c) =>
                                          int.parse(c.id) == selectedCategoryId,
                                    );

                                    String? nuevoNombre =
                                        await _mostrarDialogoCategoriaBonita(
                                      valorInicial: catActual.name,
                                    );

                                    if (nuevoNombre != null &&
                                        nuevoNombre.isNotEmpty) {
                                      final auth = context.read<AuthProvider>();
                                      bool success =
                                          await ApiService.updateCategory(
                                        auth.token!,
                                        selectedCategoryId!,
                                        nuevoNombre,
                                        type,
                                      );
                                      if (success) {
                                        await loadCategories();
                                        setStateDialog(() {
                                          localCategories =
                                              List.from(categories);
                                        });
                                      }
                                    }
                                  },
                                ),
                                // BOTÃ“N ELIMINAR
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    bool? confirmar = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                            "Â¿Eliminar categorÃ­a?"),
                                        content: const Text(
                                            "Esta acciÃ³n no se puede deshacer."),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text("Cancelar"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text("Eliminar",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmar == true) {
                                      final auth = context.read<AuthProvider>();
                                      bool success =
                                          await ApiService.deleteCategory(
                                        auth.token!,
                                        selectedCategoryId!,
                                      );
                                      if (success) {
                                        await loadCategories();
                                        setStateDialog(() {
                                          localCategories =
                                              List.from(categories);
                                          selectedCategoryId =
                                              null; // Reset de selecciÃ³n
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "CategorÃ­a eliminada con Ã©xito")),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Error al eliminar la categorÃ­a")),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 25),

                          //AQUÃ REGRESA LA FECHA
                          InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              setStateDialog(() {
                                allowFutureMovement = !allowFutureMovement;
                                final parsed = DateFormat("MM/dd/yyyy")
                                    .tryParse(dateController.text);
                                final todayOnly = DateTime(
                                    today.year, today.month, today.day);
                                if (!allowFutureMovement &&
                                    parsed != null &&
                                    parsed.isAfter(todayOnly)) {
                                  dateController.text =
                                      DateFormat("MM/dd/yyyy").format(today);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: allowFutureMovement
                                      ? [
                                          const Color(0xFF2563EB),
                                          const Color(0xFF10B981),
                                        ]
                                      : [
                                          isDark
                                              ? const Color(0xFF17231F)
                                              : const Color(0xFFF8FAFC),
                                          isDark
                                              ? const Color(0xFF10231E)
                                              : const Color(0xFFEFF6FF),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: allowFutureMovement
                                      ? Colors.transparent
                                      : const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: allowFutureMovement
                                          ? Colors.white.withOpacity(0.18)
                                          : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      type == "ingreso"
                                          ? Icons.trending_up_rounded
                                          : Icons.event_available_rounded,
                                      color: allowFutureMovement
                                          ? Colors.white
                                          : const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          type == "ingreso"
                                              ? "Ingresos futuros"
                                              : "Gastos futuros",
                                          style: TextStyle(
                                            color: allowFutureMovement
                                                ? Colors.white
                                                : null,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          allowFutureMovement
                                              ? "Fechas futuras habilitadas"
                                              : "Toca para permitir fechas futuras",
                                          style: TextStyle(
                                            color: allowFutureMovement
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    allowFutureMovement
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: allowFutureMovement
                                        ? Colors.white
                                        : const Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const TranslatedText("Fecha",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              final parsedDate = DateFormat("MM/dd/yyyy")
                                  .tryParse(dateController.text);
                              final maxDate = allowFutureMovement
                                  ? DateTime(2101)
                                  : DateTime(
                                      today.year,
                                      today.month,
                                      today.day,
                                    );
                              final safeInitialDate = (parsedDate != null &&
                                      !parsedDate.isAfter(maxDate))
                                  ? parsedDate
                                  : maxDate;
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: safeInitialDate,
                                firstDate: DateTime(2000),
                                lastDate: maxDate,
                              );
                              if (picked != null) {
                                setStateDialog(() => dateController.text =
                                    DateFormat("MM/dd/yyyy").format(picked));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color:
                                    isDark ? Colors.black12 : Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 12),
                                  Text("${dateController.text}"),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          //Notas
                          const TranslatedText("Notas",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: desc,
                            decoration: InputDecoration(
                              hintText: "Escribe una nota...",
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black12 : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                          // BOTÃ“N GUARDAR

                          //(SizedBox despuÃ©s del TextField de Notas)
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                elevation: 0,
                              ),
                              onPressed: isLoadingDialog
                                  ? null
                                  : () async {
                                      // 1. Validar que el monto no estÃ© vacÃ­o o sea 0
                                      String cleanText = amount.text
                                          .replaceAll(RegExp(r'[^0-9.]'), '');
                                      double montoFinal =
                                          double.tryParse(cleanText) ?? 0.0;
                                      DateTime fechaFinal =
                                          DateFormat("MM/dd/yyyy")
                                              .parse(dateController.text);
                                      if (selectedCategoryId == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Selecciona una categorÃ­a")),
                                        );
                                        return;
                                      }

                                      int categoryId = selectedCategoryId!;

                                      if (montoFinal <= 0) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: TranslatedText(
                                                  "Por favor ingresa un monto vÃ¡lido")),
                                        );
                                        return;
                                      }

                                      if (desc.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: TranslatedText(
                                                  "Por favor ingresa una descripciÃ³n")),
                                        );
                                        return;
                                      }

                                      setStateDialog(
                                          () => isLoadingDialog = true);

                                      final auth = context.read<AuthProvider>();

                                      bool success;
                                      if (edit == null) {
                                        // ES NUEVO
                                        success =
                                            await ApiService.createTransaction(
                                          auth.token!,
                                          type,
                                          montoFinal,
                                          desc.text,
                                          categoryId,
                                          fechaFinal,
                                        );
                                        if (type == "ingreso") {
                                          context
                                              .read<AuthProvider>()
                                              .actualizarMetasConIngreso(
                                                  montoFinal);
                                        }
                                      } else {
                                        // ES EDICIÃ“N
                                        success =
                                            await ApiService.updateTransaction(
                                          auth.token!,
                                          edit.id!,
                                          type,
                                          montoFinal,
                                          desc.text,
                                          categoryId,
                                          fechaFinal,
                                        );
                                      }

                                      if (success) {
                                        if (!mounted) return;
                                        Navigator.pop(
                                            context); // Cierra el formulario
                                        loadTransactions(); // Recarga la lista principal
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(edit == null
                                                  ? "Creado con Ã©xito"
                                                  : "Actualizado con Ã©xito")),
                                        );
                                      } else {
                                        setStateDialog(
                                            () => isLoadingDialog = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: TranslatedText(
                                                  "Error al guardar en el servidor")),
                                        );
                                      }
                                    },
                              child: isLoadingDialog
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : TranslatedText(
                                      edit == null
                                          ? "Guardar Movimiento"
                                          : "Actualizar Movimiento",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          // DropdownButton
                        ], // Cierre de children
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Helper para los botones de tipo
  Widget _buildTypeButton(
      String title, String current, Function(String) onTap, bool isDark) {
    bool isSelected = title == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF064E3B) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 4)
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title[0].toUpperCase() + title.substring(1),
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.green)
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void confirmDelete(TransactionModel t) {
    showDialog(
      context: context,
      builder: (_) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text("Â¿Eliminar movimiento?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Se eliminarÃ¡ '${t.description}'"),
                  const SizedBox(height: 8),
                  Text("Monto: \$${t.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text("Cancelar",
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          // ... tu lÃ³gica de borrado que ya tienes ...
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("Eliminar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _mostrarDialogoNuevaCategoria({String? valorInicial}) async {
    TextEditingController controller = TextEditingController();
    controller.text = valorInicial ?? '';

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const TranslatedText("Nueva categorÃ­a"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Ej: Transporte, Comida...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            child: const TranslatedText("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<String?> _mostrarDialogoCategoriaBonita({String? valorInicial}) async {
    final controller = TextEditingController(text: valorInicial ?? '');
    bool showError = false;

    return showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final hasError = showError && controller.text.trim().isEmpty;

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10231E) : Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.category_rounded,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          valorInicial == null
                              ? "Nueva categoria"
                              : "Editar categoria",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Organiza tus movimientos con nombres claros y faciles de reconocer.",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setStateDialog(() {}),
                    decoration: InputDecoration(
                      labelText: "Nombre de categoria",
                      hintText: "Ej: Transporte, Comida, Nomina",
                      prefixIcon: const Icon(
                        Icons.label_outline_rounded,
                        color: Color(0xFF10B981),
                      ),
                      filled: true,
                      fillColor:
                          isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: hasError
                              ? Colors.redAccent
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: hasError
                              ? Colors.redAccent
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: hasError
                              ? Colors.redAccent
                              : const Color(0xFF10B981),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "Este campo es obligatorio.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text("Cancelar"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setStateDialog(() => showError = true);
                            if (controller.text.trim().isEmpty) return;
                            Navigator.pop(context, controller.text.trim());
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Guardar",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Constructor de items para el menÃº
  Widget _buildDrawerItem(
      {required IconData icon,
      required String title,
      String? subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: TranslatedText(title,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

// El Modal de Idioma pero llamado desde afuera
  void _showLanguagePicker(
      BuildContext context, LanguageProvider langProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize:
              MainAxisSize.min, // Hace que el modal solo ocupe lo necesario
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: TranslatedText("Selecciona Idioma",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: langProvider.supportedLanguages.length,
                itemBuilder: (context, index) {
                  String key =
                      langProvider.supportedLanguages.keys.elementAt(index);
                  String name = langProvider.supportedLanguages[key]!;
                  return ListTile(
                    title: Text(name),
                    trailing: langProvider.currentLanguage == key
                        ? const Icon(Icons.check, color: Colors.green)
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
  }

  void _showProfileInfoSheet() {
    final usernameController = TextEditingController(text: username);
    final ageController = TextEditingController(text: age);
    final descriptionController = TextEditingController(text: description);
    final phoneController = TextEditingController(text: phone);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10231E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundImage: (profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty)
                            ? NetworkImage(profileImageUrl!)
                            : null,
                        child: (profileImageUrl == null ||
                                profileImageUrl!.isEmpty)
                            ? const Icon(Icons.person_rounded, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? "Mi perfil" : name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              usernameController.text.trim().isEmpty
                                  ? "Agrega tu usuario"
                                  : "@${usernameController.text.trim()}",
                              style: const TextStyle(
                                color: Color(0xFFE1306C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _profileInput(
                    controller: usernameController,
                    label: "Nombre de usuario",
                    hint: "ej: alex_finara",
                    icon: Icons.alternate_email_rounded,
                  ),
                  _profileInput(
                    controller: ageController,
                    label: "Edad",
                    hint: "ej: 24",
                    icon: Icons.cake_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  _profileInput(
                    controller: phoneController,
                    label: "Telefono",
                    hint: "ej: +57 300 000 0000",
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  _profileInput(
                    controller: descriptionController,
                    label: "Descripcion",
                    hint: "Cuentanos algo sobre ti",
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              final auth = context.read<AuthProvider>();
                              final result = await ApiService.updateProfileInfo(
                                auth.token!,
                                username: usernameController.text,
                                age: ageController.text,
                                description: descriptionController.text,
                                phone: phoneController.text,
                              );

                              if (!mounted) return;

                              if (result != null) {
                                setState(() {
                                  username = result["username"] ?? "";
                                  age = result["age"]?.toString() ?? "";
                                  description = result["description"] ?? "";
                                  phone = result["phone"] ?? "";
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Informacion actualizada"),
                                  ),
                                );
                              } else {
                                setSheetState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("No se pudo guardar"),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE1306C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Guardar informacion",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFE1306C)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE1306C), width: 1.6),
          ),
        ),
      ),
    );
  }

  void _showSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF10231E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: Color(0xFF2563EB), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Soporte Finara",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                "Estamos listos para ayudarte con tu cuenta, movimientos, metas o dudas de la app.",
              ),
              const SizedBox(height: 18),
              _supportTile(Icons.email_rounded, "Correo", "soporte@finara.app"),
              _supportTile(Icons.chat_rounded, "Chat de ayuda",
                  "Respuesta en horario laboral"),
              _supportTile(Icons.bug_report_rounded, "Reportar problema",
                  "Incluye pantalla y pasos para reproducirlo"),
            ],
          ),
        );
      },
    );
  }

  Widget _supportTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final auth = context.read<AuthProvider>(); // Obtenemos el token
    final ImagePicker picker = ImagePicker();

    // 1. Seleccionar la imagen
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Comprimimos un poco para que suba mÃ¡s rÃ¡pido
    );

    if (image == null) return;

    // 2. Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/users/upload-profile-picture'),
      );

      // 3. Agregar el Token (Indispensable para tu Backend)
      request.headers['Authorization'] = 'Bearer ${auth.token}';

      if (kIsWeb) {
        var bytes = await image.readAsBytes();
        request.files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: image.name));
      } else {
        request.files
            .add(await http.MultipartFile.fromPath('file', image.path));
      }

      // 4. Enviar y procesar
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Quitar el cÃ­rculo de carga
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          // El timestamp ?v= es un truco excelente para refrescar la imagen
          profileImageUrl =
              "${data['url']}?v=${DateTime.now().millisecondsSinceEpoch}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto de perfil actualizada âœ…")),
        );
      } else {
        throw "Error del servidor: ${response.statusCode}";
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Quitar carga si hay error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir imagen: $e")),
      );
    }
  }

  String formatCurrency(double amount) {
    // Crea un formato: $1,234.56
    final formatter = NumberFormat.currency(locale: "en_US", symbol: "\$");
    return formatter.format(amount);
  }

  void _crearMeta() {
    TextEditingController nombre = TextEditingController();
    TextEditingController montoMeta = TextEditingController();
    TextEditingController ahorroMensual = TextEditingController();
    bool showValidationErrors = false;
    XFile? pickedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final ImagePicker picker = ImagePicker();

            Future<void> pickMetaImage() async {
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setStateDialog(() {
                  pickedImage = image;
                });
              }
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            OutlineInputBorder metaBorder(bool hasError) => OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: hasError ? Colors.redAccent : Colors.grey[200]!,
                    width: hasError ? 1.6 : 1,
                  ),
                );
            final nombreError =
                showValidationErrors && nombre.text.trim().isEmpty;
            final montoError =
                showValidationErrors && montoMeta.text.trim().isEmpty;
            final ahorroError =
                showValidationErrors && ahorroMensual.text.trim().isEmpty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  //Indicador de arrastre
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 25,
                        right: 25,
                        top: 20,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //TITULO
                          const Center(
                            child: Text(
                              "Nueva meta de ahorro",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF064E3B), // verde oscuro
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          //NOMBRE
                          const Text(
                            "Nombre",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: nombre,
                            onChanged: (_) => setStateDialog(() {}),
                            decoration: InputDecoration(
                              hintText: "Ej: Viaje, Moto, Laptop...",
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black12 : Colors.grey[50],
                              border: metaBorder(nombreError),
                              enabledBorder: metaBorder(nombreError),
                              focusedBorder: metaBorder(nombreError),
                            ),
                          ),

                          const SizedBox(height: 25),

                          //MONTO META
                          const Text(
                            "Monto objetivo",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: montoMeta,
                            onChanged: (_) => setStateDialog(() {}),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.attach_money,
                                  color: Color(0xFF064E3B)),
                              hintText: "0.00",
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black12 : Colors.grey[50],
                              border: metaBorder(montoError),
                              enabledBorder: metaBorder(montoError),
                              focusedBorder: metaBorder(montoError),
                            ),
                          ),

                          const SizedBox(height: 25),

                          //AHORRO MENSUAL
                          const Text(
                            "Ahorro mensual",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: ahorroMensual,
                            onChanged: (_) => setStateDialog(() {}),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.savings,
                                  color: Color(0xFF064E3B)),
                              hintText: "0.00",
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black12 : Colors.grey[50],
                              border: metaBorder(ahorroError),
                              enabledBorder: metaBorder(ahorroError),
                              focusedBorder: metaBorder(ahorroError),
                            ),
                          ),

                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: pickMetaImage,
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.grey[200],
                              ),
                              child: pickedImage == null
                                  ? const Center(
                                      child: Icon(Icons.add_a_photo,
                                          size: 40, color: Colors.grey),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.file(
                                        File(pickedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 35),

                          //BTN GUARDAR
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF00C853), // verde claro
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: () async {
                                String? base64Image;

                                if (pickedImage != null) {
                                  final bytes =
                                      await pickedImage!.readAsBytes();
                                  base64Image = base64Encode(bytes);
                                }

                                setStateDialog(
                                    () => showValidationErrors = true);
                                if (nombre.text.trim().isEmpty ||
                                    montoMeta.text.trim().isEmpty ||
                                    ahorroMensual.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Completa los campos obligatorios")),
                                  );
                                  return;
                                }

                                context.read<AuthProvider>().addMeta(
                                      MetaAhorro(
                                        nombre: nombre.text,
                                        montoMeta: double.parse(montoMeta.text),
                                        ahorroMensual: double.tryParse(
                                                ahorroMensual.text) ??
                                            0,
                                        imageData: base64Image,
                                      ),
                                    );

                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Guardar meta",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editarMeta(int index) {
    final metas = context.read<AuthProvider>().metas;
    final meta = metas[index];

    TextEditingController nombre = TextEditingController(text: meta.nombre);
    TextEditingController montoMeta =
        TextEditingController(text: meta.montoMeta.toString());
    TextEditingController ahorroMensual =
        TextEditingController(text: meta.ahorroMensual.toString());
    bool showValidationErrors = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Funciones para seleccionar imagen de meta
            final ImagePicker picker = ImagePicker();
            XFile? pickedImage;

            Future<void> pickMetaImage() async {
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                pickedImage = image;
              }
            }

            // Estilos y validaciones
            final isDark = Theme.of(context).brightness == Brightness.dark;
            OutlineInputBorder metaBorder(bool hasError) => OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: hasError ? Colors.redAccent : Colors.grey[300]!,
                    width: hasError ? 1.6 : 1,
                  ),
                );
            final nombreError =
                showValidationErrors && nombre.text.trim().isEmpty;
            final montoError =
                showValidationErrors && montoMeta.text.trim().isEmpty;
            final ahorroError =
                showValidationErrors && ahorroMensual.text.trim().isEmpty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 25,
                  right: 25,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  children: [
                    const Text("Editar Meta",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF064E3B))),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nombre,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: "Nombre",
                        filled: true,
                        fillColor: isDark ? Colors.black12 : Colors.grey[50],
                        border: metaBorder(nombreError),
                        enabledBorder: metaBorder(nombreError),
                        focusedBorder: metaBorder(nombreError),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: montoMeta,
                      onChanged: (_) => setStateDialog(() {}),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Monto objetivo",
                        filled: true,
                        fillColor: isDark ? Colors.black12 : Colors.grey[50],
                        border: metaBorder(montoError),
                        enabledBorder: metaBorder(montoError),
                        focusedBorder: metaBorder(montoError),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ahorroMensual,
                      onChanged: (_) => setStateDialog(() {}),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Ahorro mensual",
                        filled: true,
                        fillColor: isDark ? Colors.black12 : Colors.grey[50],
                        border: metaBorder(ahorroError),
                        enabledBorder: metaBorder(ahorroError),
                        focusedBorder: metaBorder(ahorroError),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setStateDialog(() => showValidationErrors = true);
                        if (nombre.text.trim().isEmpty ||
                            montoMeta.text.trim().isEmpty ||
                            ahorroMensual.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Completa los campos obligatorios"),
                            ),
                          );
                          return;
                        }
                        context.read<AuthProvider>().editarMeta(
                              index,
                              MetaAhorro(
                                nombre: nombre.text,
                                montoMeta: double.parse(montoMeta.text),
                                ahorroMensual: double.parse(ahorroMensual.text),
                                montoActual: meta.montoActual,
                                aportes: meta.aportes,
                              ),
                            );

                        Navigator.pop(context);
                      },
                      child: const Text("Guardar"),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _eliminarMeta(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar meta"),
        content: const Text("Â¿Seguro?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().eliminarMeta(index);
              Navigator.pop(context);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _agregarAporte(int index) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agregar dinero"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              final monto = double.tryParse(controller.text) ?? 0;

              context.read<AuthProvider>().agregarDineroMeta(index, monto);

              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }
}
